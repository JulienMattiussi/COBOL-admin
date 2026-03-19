/*
 * C helper library for COBOL Admin
 * Provides HTTP (libcurl) and JSON (cJSON) functions
 * callable from GnuCOBOL via CALL "function-name"
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
#include "cJSON.h"

/* --- HTTP helpers using libcurl --- */

int cobol_http_get(const char *url, const char *response_file,
                   const char *header_file) {
    CURL *curl = curl_easy_init();
    if (!curl) return -1;

    FILE *resp = fopen(response_file, "w");
    if (!resp) { curl_easy_cleanup(curl); return -2; }

    FILE *hdrs = NULL;
    if (header_file && header_file[0]) {
        hdrs = fopen(header_file, "w");
    }

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, resp);
    if (hdrs) {
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, hdrs);
    }
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);

    CURLcode res = curl_easy_perform(curl);

    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

    fclose(resp);
    if (hdrs) fclose(hdrs);
    curl_easy_cleanup(curl);

    if (res != CURLE_OK) return -3;
    if (http_code >= 400) return (int)http_code;
    return 0;
}

int cobol_http_put(const char *url, const char *json_file) {
    /* Read JSON body from file */
    FILE *f = fopen(json_file, "r");
    if (!f) return -2;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *body = malloc(len + 1);
    if (!body) { fclose(f); return -4; }
    fread(body, 1, len, f);
    body[len] = 0;
    fclose(f);

    CURL *curl = curl_easy_init();
    if (!curl) { free(body); return -1; }

    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT");
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);

    /* Discard response body */
    FILE *devnull = fopen("/dev/null", "w");
    if (devnull) curl_easy_setopt(curl, CURLOPT_WRITEDATA, devnull);

    CURLcode res = curl_easy_perform(curl);

    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

    if (devnull) fclose(devnull);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    free(body);

    if (res != CURLE_OK) return -3;
    if (http_code >= 400) return (int)http_code;
    return 0;
}

int cobol_http_delete(const char *url) {
    CURL *curl = curl_easy_init();
    if (!curl) return -1;

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "DELETE");
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);

    FILE *devnull = fopen("/dev/null", "w");
    if (devnull) curl_easy_setopt(curl, CURLOPT_WRITEDATA, devnull);

    CURLcode res = curl_easy_perform(curl);

    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

    if (devnull) fclose(devnull);
    curl_easy_cleanup(curl);

    if (res != CURLE_OK) return -3;
    if (http_code >= 400) return (int)http_code;
    return 0;
}

int cobol_http_post(const char *url, const char *json_file,
                    const char *response_file) {
    /* Read JSON body from file */
    FILE *f = fopen(json_file, "r");
    if (!f) return -2;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *body = malloc(len + 1);
    if (!body) { fclose(f); return -4; }
    fread(body, 1, len, f);
    body[len] = 0;
    fclose(f);

    CURL *curl = curl_easy_init();
    if (!curl) { free(body); return -1; }

    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");

    FILE *resp = fopen(response_file, "w");
    if (!resp) { free(body); curl_easy_cleanup(curl); return -2; }

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, resp);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);

    CURLcode res = curl_easy_perform(curl);

    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

    fclose(resp);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    free(body);

    if (res != CURLE_OK) return -3;
    if (http_code >= 400) return (int)http_code;
    return 0;
}

/*
 * Extract "id" field from a JSON file, return as integer
 */
int cobol_json_extract_id(const char *json_file, int *id_out) {
    *id_out = 0;
    FILE *f = fopen(json_file, "r");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *data = malloc(len + 1);
    if (!data) { fclose(f); return -2; }
    fread(data, 1, len, f);
    data[len] = 0;
    fclose(f);

    cJSON *root = cJSON_Parse(data);
    free(data);
    if (!root) return -3;

    cJSON *id = cJSON_GetObjectItem(root, "id");
    if (id && cJSON_IsNumber(id)) {
        *id_out = id->valueint;
    }
    cJSON_Delete(root);
    return 0;
}

/* --- JSON helpers using cJSON --- */

/*
 * Convert a JSON object to TSV: key<tab>value per line
 * Arrays are joined with ", "
 * Mode: "object" = single object, "array" = array of objects
 */
int cobol_json_to_tsv(const char *json_file, const char *tsv_file,
                      const char *mode, const char *fields_csv) {
    FILE *f = fopen(json_file, "r");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *data = malloc(len + 1);
    if (!data) { fclose(f); return -2; }
    fread(data, 1, len, f);
    data[len] = 0;
    fclose(f);

    cJSON *root = cJSON_Parse(data);
    free(data);
    if (!root) return -3;

    FILE *out = fopen(tsv_file, "w");
    if (!out) { cJSON_Delete(root); return -4; }

    if (strcmp(mode, "object") == 0) {
        /* Single object: output key<tab>value per property */
        cJSON *item;
        cJSON_ArrayForEach(item, root) {
            if (cJSON_IsArray(item)) {
                fprintf(out, "%s\t", item->string);
                int first = 1;
                cJSON *el;
                cJSON_ArrayForEach(el, item) {
                    if (!first) fprintf(out, ", ");
                    if (cJSON_IsString(el))
                        fprintf(out, "%s", el->valuestring);
                    else {
                        char *s = cJSON_PrintUnformatted(el);
                        fprintf(out, "%s", s);
                        free(s);
                    }
                    first = 0;
                }
                fprintf(out, "\n");
            } else if (cJSON_IsString(item)) {
                fprintf(out, "%s\t%s\n", item->string,
                        item->valuestring);
            } else {
                char *s = cJSON_PrintUnformatted(item);
                fprintf(out, "%s\t%s\n", item->string, s);
                free(s);
            }
        }
    } else if (strcmp(mode, "array") == 0 && fields_csv) {
        /* Array of objects: output field values as TSV rows */
        /* Parse fields_csv into array */
        char fields_buf[2048];
        strncpy(fields_buf, fields_csv, sizeof(fields_buf) - 1);
        fields_buf[sizeof(fields_buf) - 1] = 0;

        char *field_names[64];
        int field_count = 0;
        char *tok = strtok(fields_buf, ",");
        while (tok && field_count < 64) {
            /* trim leading spaces */
            while (*tok == ' ') tok++;
            field_names[field_count++] = tok;
            tok = strtok(NULL, ",");
        }

        cJSON *row;
        cJSON_ArrayForEach(row, root) {
            for (int i = 0; i < field_count; i++) {
                if (i > 0) fprintf(out, "\t");
                cJSON *val = cJSON_GetObjectItem(row,
                                                  field_names[i]);
                if (!val || cJSON_IsNull(val)) {
                    /* empty */
                } else if (cJSON_IsString(val)) {
                    fprintf(out, "%s", val->valuestring);
                } else if (cJSON_IsArray(val)) {
                    int first = 1;
                    cJSON *el;
                    cJSON_ArrayForEach(el, val) {
                        if (!first) fprintf(out, ", ");
                        if (cJSON_IsString(el))
                            fprintf(out, "%s", el->valuestring);
                        else {
                            char *s = cJSON_PrintUnformatted(el);
                            fprintf(out, "%s", s);
                            free(s);
                        }
                        first = 0;
                    }
                } else {
                    char *s = cJSON_PrintUnformatted(val);
                    fprintf(out, "%s", s);
                    free(s);
                }
            }
            fprintf(out, "\n");
        }
    }

    fclose(out);
    cJSON_Delete(root);
    return 0;
}

/*
 * Extract unique base resource paths from OpenAPI JSON
 * Reads .paths keys, splits on "/", takes [1], deduplicates
 * Outputs one resource name per line, sorted
 */
int cobol_json_resources(const char *json_file,
                         const char *output_file) {
    FILE *f = fopen(json_file, "r");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *data = malloc(len + 1);
    if (!data) { fclose(f); return -2; }
    fread(data, 1, len, f);
    data[len] = 0;
    fclose(f);

    cJSON *root = cJSON_Parse(data);
    free(data);
    if (!root) return -3;

    cJSON *paths = cJSON_GetObjectItem(root, "paths");
    if (!paths) { cJSON_Delete(root); return -4; }

    /* Collect unique resource names */
    char resources[100][64];
    int count = 0;

    cJSON *path;
    cJSON_ArrayForEach(path, paths) {
        const char *key = path->string;
        if (key[0] == '/') key++;
        /* Extract first segment */
        char seg[64] = {0};
        int i = 0;
        while (key[i] && key[i] != '/' && i < 63) {
            seg[i] = key[i];
            i++;
        }
        seg[i] = 0;
        if (seg[0] == 0) continue;

        /* Check for duplicate */
        int dup = 0;
        for (int j = 0; j < count; j++) {
            if (strcmp(resources[j], seg) == 0) { dup = 1; break; }
        }
        if (!dup && count < 100) {
            strcpy(resources[count++], seg);
        }
    }

    /* Sort */
    for (int i = 0; i < count - 1; i++)
        for (int j = i + 1; j < count; j++)
            if (strcmp(resources[i], resources[j]) > 0) {
                char tmp[64];
                strcpy(tmp, resources[i]);
                strcpy(resources[i], resources[j]);
                strcpy(resources[j], tmp);
            }

    FILE *out = fopen(output_file, "w");
    if (!out) { cJSON_Delete(root); return -5; }
    for (int i = 0; i < count; i++)
        fprintf(out, "%s\n", resources[i]);
    fclose(out);

    cJSON_Delete(root);
    return 0;
}

/*
 * Extract fields for a resource from OpenAPI schema
 * Resolves $ref from the GET response, reads properties
 * Checks if *Input schema has the field (editable flag)
 * Output: name<tab>type<tab>editable(1/0) per line
 */
int cobol_json_fields(const char *json_file, const char *resource,
                      const char *output_file) {
    FILE *f = fopen(json_file, "r");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *data = malloc(len + 1);
    if (!data) { fclose(f); return -2; }
    fread(data, 1, len, f);
    data[len] = 0;
    fclose(f);

    cJSON *root = cJSON_Parse(data);
    free(data);
    if (!root) return -3;

    /* Build path key: /{resource} */
    char path_key[128];
    snprintf(path_key, sizeof(path_key), "/%s", resource);

    cJSON *paths = cJSON_GetObjectItem(root, "paths");
    cJSON *path_obj = cJSON_GetObjectItem(paths, path_key);
    if (!path_obj) { cJSON_Delete(root); return -4; }

    /* Navigate: .get.responses.200.content.application/json.schema */
    cJSON *get_op = cJSON_GetObjectItem(path_obj, "get");
    if (!get_op) { cJSON_Delete(root); return -4; }
    cJSON *responses = cJSON_GetObjectItem(get_op, "responses");
    cJSON *r200 = cJSON_GetObjectItem(responses, "200");
    cJSON *content = cJSON_GetObjectItem(r200, "content");
    cJSON *json_ct = cJSON_GetObjectItem(content,
                                          "application/json");
    cJSON *schema = cJSON_GetObjectItem(json_ct, "schema");

    /* Resolve $ref from items or directly */
    cJSON *ref = NULL;
    cJSON *items = cJSON_GetObjectItem(schema, "items");
    if (items) ref = cJSON_GetObjectItem(items, "$ref");
    if (!ref) ref = cJSON_GetObjectItem(schema, "$ref");
    if (!ref || !cJSON_IsString(ref)) {
        cJSON_Delete(root);
        return -5;
    }

    /* Extract schema name from "#/components/schemas/Name" */
    const char *ref_str = ref->valuestring;
    const char *schema_name = strrchr(ref_str, '/');
    if (!schema_name) { cJSON_Delete(root); return -5; }
    schema_name++; /* skip '/' */

    /* Get the schema */
    cJSON *components = cJSON_GetObjectItem(root, "components");
    cJSON *schemas = cJSON_GetObjectItem(components, "schemas");
    cJSON *the_schema = cJSON_GetObjectItem(schemas, schema_name);
    if (!the_schema) { cJSON_Delete(root); return -6; }

    cJSON *properties = cJSON_GetObjectItem(the_schema,
                                             "properties");
    if (!properties) { cJSON_Delete(root); return -6; }

    /* Build Input schema name */
    char input_name[128];
    snprintf(input_name, sizeof(input_name), "%sInput", schema_name);
    cJSON *input_schema = cJSON_GetObjectItem(schemas, input_name);
    cJSON *input_props = input_schema ?
        cJSON_GetObjectItem(input_schema, "properties") : NULL;

    FILE *out = fopen(output_file, "w");
    if (!out) { cJSON_Delete(root); return -7; }

    cJSON *prop;
    cJSON_ArrayForEach(prop, properties) {
        const char *name = prop->string;
        cJSON *type_obj = cJSON_GetObjectItem(prop, "type");
        const char *type = type_obj && cJSON_IsString(type_obj) ?
            type_obj->valuestring : "string";
        int editable = input_props &&
            cJSON_GetObjectItem(input_props, name) ? 1 : 0;
        fprintf(out, "%s\t%s\t%d\n", name, type, editable);
    }

    fclose(out);
    cJSON_Delete(root);
    return 0;
}

/*
 * Convert URL-encoded form data to JSON
 * Reads from input_file, writes JSON to output_file
 */
int cobol_form_to_json(const char *input_file,
                       const char *output_file) {
    FILE *f = fopen(input_file, "r");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *data = malloc(len + 1);
    if (!data) { fclose(f); return -2; }
    fread(data, 1, len, f);
    data[len] = 0;
    fclose(f);

    /* Trim trailing whitespace/nulls */
    while (len > 0 && (data[len-1] == ' ' || data[len-1] == '\n'
           || data[len-1] == '\r' || data[len-1] == 0))
        data[--len] = 0;

    cJSON *obj = cJSON_CreateObject();
    if (!obj) { free(data); return -3; }

    /* Parse key=value&key=value */
    char *ptr = data;
    while (ptr && *ptr) {
        char *amp = strchr(ptr, '&');
        if (amp) *amp = 0;

        char *eq = strchr(ptr, '=');
        if (eq) {
            *eq = 0;
            char *key = ptr;
            char *val = eq + 1;

            /* URL-decode value in-place */
            char *src = val, *dst = val;
            while (*src) {
                if (*src == '+') {
                    *dst++ = ' ';
                    src++;
                } else if (*src == '%' && src[1] && src[2]) {
                    char hex[3] = { src[1], src[2], 0 };
                    *dst++ = (char)strtol(hex, NULL, 16);
                    src += 3;
                } else {
                    *dst++ = *src++;
                }
            }
            *dst = 0;

            /* URL-decode key in-place */
            src = key; dst = key;
            while (*src) {
                if (*src == '+') {
                    *dst++ = ' ';
                    src++;
                } else if (*src == '%' && src[1] && src[2]) {
                    char hex[3] = { src[1], src[2], 0 };
                    *dst++ = (char)strtol(hex, NULL, 16);
                    src += 3;
                } else {
                    *dst++ = *src++;
                }
            }
            *dst = 0;

            cJSON_AddStringToObject(obj, key, val);
        }

        ptr = amp ? amp + 1 : NULL;
    }

    char *json = cJSON_PrintUnformatted(obj);
    cJSON_Delete(obj);
    free(data);

    if (!json) return -4;

    FILE *out = fopen(output_file, "w");
    if (!out) { free(json); return -5; }
    fputs(json, out);
    fclose(out);
    free(json);

    return 0;
}

/*
 * Clean up all temp files used during request processing
 */
void cobol_cleanup_temp(void) {
    const char *files[] = {
        "/tmp/response.json",
        "/tmp/showdata.tsv",
        "/tmp/listresponse.json",
        "/tmp/listdata.tsv",
        "/tmp/headers.txt",
        "/tmp/formbody.txt",
        "/tmp/formjson.json",
        "/tmp/create_response.json",
        NULL
    };
    for (int i = 0; files[i]; i++) {
        remove(files[i]);
    }
}

/*
 * Extract X-Total-Count from HTTP header file
 */
int cobol_extract_total(const char *header_file, int *total) {
    *total = 0;
    FILE *f = fopen(header_file, "r");
    if (!f) return -1;

    char line[512];
    while (fgets(line, sizeof(line), f)) {
        if (strncasecmp(line, "x-total-count:", 14) == 0) {
            *total = atoi(line + 14);
            break;
        }
    }
    fclose(f);
    return 0;
}

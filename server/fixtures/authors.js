const names = [
  "Rand al'Thor", "Matrim Cauthon", "Perrin Aybara", "Egwene al'Vere",
  "Nynaeve al'Meara", "Moiraine Damodred", "Lan Mandragoran", "Elayne Trakand",
  "Min Farshaw", "Aviendha", "Thom Merrilin", "Loial", "Faile Bashere",
  "Siuan Sanche", "Elaida do Avriny", "Logain Ablar", "Gawyn Trakand",
  "Galad Damodred", "Morgase Trakand", "Gareth Bryne", "Basel Gill",
  "Tam al'Thor", "Bran al'Vere", "Cenn Buie", "Daise Congar",
  "Padan Fain", "Ingtar Shinowa", "Agelmar Jagad", "Bayle Domon",
  "Elyas Machera", "Dain Bornhald", "Geofram Bornhald", "Jaret Byar",
  "Hurin", "Ragan", "Uno Nomesta", "Masema Dagar", "Aram",
  "Raen", "Ila", "Elmindreda Farshaw", "Sheriam Bayanar",
  "Leane Sharif", "Alanna Mosvani", "Verin Mathwin", "Cadsuane Melaidhrin",
  "Sorilea", "Amys", "Bair", "Melaine",
  "Rhuarc", "Gaul", "Bain", "Chiad",
  "Sulin", "Berelain sur Paendrag", "Dobraine Taborwin", "Darlin Sisnera",
  "Davram Bashere", "Tenobia Kazadi", "Easar Togita", "Ethenielle Cosaru",
  "Paitar Nachiman", "Tuon Athaem", "Selucia", "Karede Sansen",
  "Tylee Khirgan", "Egeanin Tamarath", "Bayle Domon", "Juilin Sandar",
  "Thera", "Setalle Anan", "Lini Eltring", "Martyn Tallanvor",
  "Birgitte Silverbow", "Areina Nermasiv", "Nicola Treehill", "Theodrin Dabei",
  "Faolain Orande", "Myrelle Berengari", "Nisao Dachen", "Merilille Ceandevin",
  "Vandene Namelle", "Adeleas Namelle", "Careane Fransi", "Sareitha Tomares",
  "Kumira", "Daigian Moseneillin", "Eben Hopwil", "Jahar Narishma",
  "Damer Flinn", "Corele Hovian", "Beldeine Nyram", "Elza Penfell",
  "Karldin Manfor", "Hopwil Eben", "Fedwin Morr", "Mazrim Taim",
  "Toveine Gazal", "Gabrelle Brawley", "Mishraile", "Taim Mazrim",
];

function toEmail(name) {
  return name
    .toLowerCase()
    .replace(/'/g, "")
    .replace(/\s+/g, ".")
    + "@wot.com";
}

module.exports = names.map((name, i) => ({
  id: i + 1,
  name,
  email: toEmail(name),
}));

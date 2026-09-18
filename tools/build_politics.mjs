// Curated identities at scenario start (1 January); cabinet assignments are gameplay.
import fs from 'node:fs';
const result={1936:{},2026:{}};
const palette={christian:'75a9d0',conservative:'8e9eb4',social:'cd6975',liberal:'d8bf65',green:'7bb98d',national:'9293c2',communist:'c56265',independent:'9bacae'};
function P(name,kind,names,legal=true){return{name,kind,color:palette[kind],legal,candidates:names.split(';').map((name,i)=>({name,focus:['finance','economy','defense','foreign'][i%4]}))};}
function C(y,code,head,headTitle,premier,premierTitle,parties){result[y][code]={head,head_title:headTitle,premier,premier_title:premierTitle,parties,coalition:[0]};}
const king='König',pres='Präsident',pm='Ministerpräsident';
C(2026,'DEU','Frank-Walter Steinmeier','Bundespräsident','Friedrich Merz','Bundeskanzler',[
 P('CDU','christian','Friedrich Merz;Katherina Reiche;Johann Wadephul;Carsten Linnemann'),
 P('CSU','christian','Markus Söder;Alexander Dobrindt;Dorothee Bär'),
 P('SPD','social','Lars Klingbeil;Bärbel Bas;Boris Pistorius'),
 P('Bündnis 90/Die Grünen','green','Franziska Brantner;Felix Banaszak;Katharina Dröge'),
 P('AfD','national','Alice Weidel;Tino Chrupalla;Beatrix von Storch'),
 P('Die Linke','social','Ines Schwerdtner;Jan van Aken;Heidi Reichinnek'),
 P('FDP','liberal','Christian Dürr;Wolfgang Kubicki;Johannes Vogel')]);
result[2026].DEU.coalition=[0,1,2];
result[2026].DEU.cabinet={finance:'Lars Klingbeil',economy:'Katherina Reiche',defense:'Boris Pistorius',foreign:'Johann Wadephul'};
C(2026,'FRA','Emmanuel Macron',pres,'Sébastien Lecornu','Premierminister',[
 P('Renaissance','liberal','Sébastien Lecornu;Gabriel Attal;Élisabeth Borne'),P('Rassemblement national','national','Jordan Bardella;Marine Le Pen'),P('Parti socialiste','social','Olivier Faure;Boris Vallaud'),P('Les Républicains','conservative','Bruno Retailleau;Laurent Wauquiez')]);
C(2026,'GBR','Charles III.',king,'Keir Starmer','Premierminister',[
 P('Labour Party','social','Keir Starmer;Rachel Reeves;John Healey;Yvette Cooper'),P('Conservative Party','conservative','Kemi Badenoch;Mel Stride'),P('Liberal Democrats','liberal','Ed Davey;Daisy Cooper'),P('Reform UK','national','Nigel Farage;Richard Tice')]);
C(2026,'ITA','Sergio Mattarella',pres,'Giorgia Meloni','Ministerpräsidentin',[
 P('Fratelli d’Italia','national','Giorgia Meloni;Guido Crosetto;Adolfo Urso'),P('Partito Democratico','social','Elly Schlein;Stefano Bonaccini'),P('Forza Italia','conservative','Antonio Tajani;Maurizio Gasparri'),P('Lega','national','Matteo Salvini;Giancarlo Giorgetti')]);
C(2026,'ESP','Felipe VI.',king,'Pedro Sánchez',pm,[P('PSOE','social','Pedro Sánchez;María Jesús Montero;Margarita Robles'),P('Partido Popular','conservative','Alberto Núñez Feijóo;Cuca Gamarra'),P('Vox','national','Santiago Abascal;Ignacio Garriga')]);
C(2026,'POL','Karol Nawrocki',pres,'Donald Tusk',pm,[P('Koalicja Obywatelska','liberal','Donald Tusk;Radosław Sikorski;Andrzej Domański'),P('Prawo i Sprawiedliwość','conservative','Jarosław Kaczyński;Mateusz Morawiecki'),P('Polskie Stronnictwo Ludowe','christian','Władysław Kosiniak-Kamysz;Piotr Zgorzelski')]);
C(2026,'AUT','Alexander Van der Bellen','Bundespräsident','Christian Stocker','Bundeskanzler',[P('ÖVP','christian','Christian Stocker;Claudia Plakolm;Wolfgang Hattmannsdorfer'),P('SPÖ','social','Andreas Babler;Doris Bures'),P('FPÖ','national','Herbert Kickl;Dagmar Belakowitsch'),P('NEOS','liberal','Beate Meinl-Reisinger;Christoph Wiederkehr')]);
C(2026,'CZE','Petr Pavel',pres,'Andrej Babiš',pm,[P('ANO 2011','liberal','Andrej Babiš;Alena Schillerová;Karel Havlíček'),P('ODS','conservative','Petr Fiala;Zbyněk Stanjura'),P('Česká pirátská strana','liberal','Zdeněk Hřib;Olga Richterová')]);
C(2026,'HUN','Tamás Sulyok',pres,'Viktor Orbán',pm,[P('Fidesz','conservative','Viktor Orbán;Péter Szijjártó;Gergely Gulyás'),P('Tisza','conservative','Péter Magyar;Dóra Dávid'),P('Demokratikus Koalíció','social','Klára Dobrev;Csaba Molnár')]);
C(2026,'BEL','Philippe',king,'Bart De Wever',pm,[P('N-VA','conservative','Bart De Wever;Jan Jambon;Theo Francken'),P('Mouvement Réformateur','liberal','Georges-Louis Bouchez;David Clarinval'),P('Vooruit','social','Conner Rousseau;Frank Vandenbroucke')]);
C(2026,'NLD','Willem-Alexander',king,'Dick Schoof',pm,[P('Parteilose','independent','Dick Schoof'),P('VVD','liberal','Dilan Yeşilgöz;Sophie Hermans;Eelco Heinen'),P('D66','liberal','Rob Jetten;Jan Paternotte'),P('PVV','national','Geert Wilders;Fleur Agema')]);
C(2026,'CHE','Guy Parmelin','Bundespräsident','Guy Parmelin','Bundesratsvorsitz',[P('SVP','conservative','Guy Parmelin;Albert Rösti;Marcel Dettling'),P('SP','social','Elisabeth Baume-Schneider;Beat Jans'),P('FDP.Die Liberalen','liberal','Ignazio Cassis;Karin Keller-Sutter'),P('Die Mitte','christian','Martin Pfister;Gerhard Pfister')]);
C(2026,'PRT','Marcelo Rebelo de Sousa',pres,'Luís Montenegro',pm,[P('PSD','conservative','Luís Montenegro;Joaquim Miranda Sarmento;Paulo Rangel'),P('Partido Socialista','social','José Luís Carneiro;Pedro Nuno Santos'),P('Chega','national','André Ventura;Pedro Pinto')]);
C(2026,'DNK','Frederik X.',king,'Mette Frederiksen','Ministerpräsidentin',[P('Socialdemokratiet','social','Mette Frederiksen;Nicolai Wammen;Morten Bødskov'),P('Venstre','liberal','Troels Lund Poulsen;Stephanie Lose'),P('Moderaterne','liberal','Lars Løkke Rasmussen;Lars Aagaard')]);
C(2026,'SWE','Carl XVI. Gustaf',king,'Ulf Kristersson',pm,[P('Moderaterna','conservative','Ulf Kristersson;Elisabeth Svantesson;Pål Jonson'),P('Socialdemokraterna','social','Magdalena Andersson;Mikael Damberg'),P('Sverigedemokraterna','national','Jimmie Åkesson;Mattias Karlsson')]);
C(2026,'NOR','Harald V.',king,'Jonas Gahr Støre',pm,[P('Arbeiderpartiet','social','Jonas Gahr Støre;Jens Stoltenberg;Espen Barth Eide'),P('Høyre','conservative','Erna Solberg;Ine Eriksen Søreide'),P('Fremskrittspartiet','national','Sylvi Listhaug;Ketil Solvik-Olsen')]);
C(2026,'SVK','Peter Pellegrini',pres,'Robert Fico',pm,[P('Smer-SD','social','Robert Fico;Robert Kaliňák;Juraj Blanár'),P('Progresívne Slovensko','liberal','Michal Šimečka;Tomáš Valášek'),P('Hlas-SD','social','Matúš Šutaj Eštok;Denisa Saková')]);

C(1936,'DEU','Adolf Hitler','Staats- und Regierungschef','Adolf Hitler','Reichskanzler',[
 P('NSDAP','national','Adolf Hitler;Hermann Göring;Wilhelm Frick;Joseph Goebbels'),
 P('Zentrum','christian','Heinrich Brüning;Ludwig Kaas;Joseph Wirth;Konrad Adenauer',false),
 P('SPD','social','Otto Wels;Hans Vogel;Rudolf Breitscheid',false),
 P('KPD','communist','Wilhelm Pieck;Ernst Thälmann;Walter Ulbricht',false),
 P('DNVP','conservative','Alfred Hugenberg;Kuno von Westarp',false),
 P('Deutsche Staatspartei','liberal','Theodor Heuss;Reinhold Maier',false),
 P('Parteilose','independent','Hjalmar Schacht;Konstantin von Neurath;Werner von Blomberg;Franz Gürtner;Lutz Graf Schwerin von Krosigk')]);
result[1936].DEU.coalition=[0,6];
result[1936].DEU.cabinet={finance:'Lutz Graf Schwerin von Krosigk',economy:'Hjalmar Schacht',defense:'Werner von Blomberg',foreign:'Konstantin von Neurath'};
C(1936,'FRA','Albert Lebrun',pres,'Pierre Laval','Ministerpräsident',[P('Parteilose','independent','Pierre Laval'),P('Parti radical','liberal','Édouard Herriot;Édouard Daladier'),P('SFIO','social','Léon Blum;Paul Faure'),P('Parti communiste français','communist','Maurice Thorez;Jacques Duclos')]);
C(1936,'GBR','George V.',king,'Stanley Baldwin','Premierminister',[P('Conservative Party','conservative','Stanley Baldwin;Neville Chamberlain;Anthony Eden;Winston Churchill'),P('Labour Party','social','Clement Attlee;Arthur Greenwood'),P('Liberal Party','liberal','Archibald Sinclair;David Lloyd George')]);
C(1936,'ITA','Viktor Emanuel III.',king,'Benito Mussolini',pm,[P('Partito Nazionale Fascista','national','Benito Mussolini;Dino Grandi;Italo Balbo;Galeazzo Ciano'),P('Partito Socialista Italiano','social','Pietro Nenni;Giuseppe Saragat',false),P('Partito Comunista d’Italia','communist','Palmiro Togliatti;Luigi Longo',false),P('Partito Popolare Italiano','christian','Luigi Sturzo;Alcide De Gasperi',false)]);
C(1936,'ESP','Niceto Alcalá-Zamora',pres,'Manuel Portela Valladares',pm,[P('Parteilose','independent','Manuel Portela Valladares;Joaquín Chapaprieta'),P('PSOE','social','Francisco Largo Caballero;Indalecio Prieto'),P('CEDA','christian','José María Gil-Robles;Manuel Giménez Fernández'),P('Izquierda Republicana','liberal','Manuel Azaña;Marcelino Domingo')]);
C(1936,'POL','Ignacy Mościcki',pres,'Marian Zyndram-Kościałkowski',pm,[P('Parteilose (Sanacja)','independent','Marian Zyndram-Kościałkowski;Józef Beck;Eugeniusz Kwiatkowski'),P('Polska Partia Socjalistyczna','social','Mieczysław Niedziałkowski;Zygmunt Żuławski'),P('Stronnictwo Ludowe','conservative','Wincenty Witos;Stanisław Mikołajczyk')]);
C(1936,'AUT','Wilhelm Miklas','Bundespräsident','Kurt Schuschnigg','Bundeskanzler',[P('Vaterländische Front','conservative','Kurt Schuschnigg;Ernst Rüdiger Starhemberg;Eduard Baar-Baarenfels'),P('SDAP','social','Otto Bauer;Karl Renner',false),P('Christlichsoziale Partei','christian','Leopold Kunschak;Richard Schmitz',false)]);
C(1936,'CSK','Edvard Beneš',pres,'Milan Hodža',pm,[P('RSZML (Agrarpartei)','conservative','Milan Hodža;Rudolf Beran;František Udržal'),P('Československá sociální demokracie','social','Antonín Hampl;Rudolf Bechyně'),P('Komunistická strana Československa','communist','Klement Gottwald;Antonín Zápotocký')]);
C(1936,'HUN','Miklós Horthy','Reichsverweser','Gyula Gömbös',pm,[P('Nemzeti Egység Pártja','conservative','Gyula Gömbös;Kálmán Darányi;Bálint Hóman'),P('Független Kisgazdapárt','conservative','Tibor Eckhardt;Ferenc Nagy'),P('Magyarországi Szociáldemokrata Párt','social','Károly Peyer;Anna Kéthly')]);
C(1936,'BEL','Leopold III.',king,'Paul van Zeeland',pm,[P('Katholische Partei','christian','Paul van Zeeland;Prosper Poullet'),P('Belgische Arbeiterpartei','social','Émile Vandervelde;Paul-Henri Spaak'),P('Liberale Partei','liberal','Albert Devèze;Paul Hymans')]);
C(1936,'NLD','Wilhelmina','Königin','Hendrik Colijn',pm,[P('Anti-Revolutionaire Partij','christian','Hendrik Colijn;Jan Schouten'),P('SDAP','social','Johan Willem Albarda;Willem Drees'),P('Roomsch-Katholieke Staatspartij','christian','Laurentius Deckers;Piet Aalberse')]);
C(1936,'CHE','Albert Meyer','Bundespräsident','Albert Meyer','Bundesratsvorsitz',[P('FDP','liberal','Albert Meyer;Hermann Obrecht'),P('Katholisch-Konservative Volkspartei','christian','Philipp Etter;Giuseppe Motta'),P('Bauern-, Gewerbe- und Bürgerpartei','conservative','Rudolf Minger;Eduard von Steiger')]);
C(1936,'PRT','Óscar Carmona',pres,'António de Oliveira Salazar',pm,[P('União Nacional','conservative','António de Oliveira Salazar;António Carneiro Pacheco;Pedro Teotónio Pereira'),P('Partido Republicano Português','liberal','Norton de Matos;Bernardino Machado',false),P('Partido Comunista Português','communist','Bento Gonçalves;Álvaro Cunhal',false)]);
C(1936,'DNK','Christian X.',king,'Thorvald Stauning',pm,[P('Socialdemokratiet','social','Thorvald Stauning;Hans Hedtoft;Vilhelm Buhl'),P('Radikale Venstre','liberal','Peter Munch;Jørgen Jørgensen'),P('Det Konservative Folkeparti','conservative','John Christmas Møller;Ole Bjørn Kraft')]);
C(1936,'SWE','Gustaf V.',king,'Per Albin Hansson',pm,[P('Socialdemokraterna','social','Per Albin Hansson;Ernst Wigforss;Gustav Möller'),P('Allmänna valmansförbundet','conservative','Gösta Bagge;Fritiof Domö'),P('Bondeförbundet','conservative','Axel Pehrsson-Bramstorp;Karl Gustaf Westman')]);
C(1936,'NOR','Haakon VII.',king,'Johan Nygaardsvold',pm,[P('Arbeiderpartiet','social','Johan Nygaardsvold;Halvdan Koht;Oscar Torp'),P('Høyre','conservative','Johan H. Andresen;C. J. Hambro'),P('Venstre','liberal','Johan Ludwig Mowinckel;Per Berg Lund')]);
for(const year of [1936,2026]) {
  const party=P('Christen für Deutschland','christian','Jan Mertens;Clara Winter;Tobias Falk;Miriam Seidel;Lukas Ahrens;Elisabeth Voss',year===2026);
  party.fictional=true;
  party.short='CfD';
  party.description='Fiktive Spielpartei: christlich-soziale Politik, Familienförderung und regionale Wirtschaft. Ihr politischer Weg wird vom Spieler bestimmt.';
  party.candidates.forEach((p,i)=>{p.fictional=true;p.portrait=i;p.focus=['foreign','finance','economy','defense','foreign','finance'][i];});
  result[year].DEU.parties.push(party);
}
for(const countries of Object.values(result)) for(const c of Object.values(countries)) {
  c.sources=[`https://en.wikipedia.org/wiki/${encodeURIComponent(c.premier.replaceAll(' ','_'))}`];
  c.parties.forEach((p,party)=>p.candidates.forEach((candidate,index)=>{candidate.id=`${party}:${index}`;candidate.party=party;}));
  for(const [role,name] of Object.entries(c.cabinet??{})) for(const p of c.parties) for(const candidate of p.candidates) if(candidate.name===name) candidate.focus=role;
}
fs.writeFileSync('data/politics.json',JSON.stringify(result,null,2));
console.log('Politics:',Object.values(result).reduce((n,c)=>n+Object.values(c).reduce((m,s)=>m+s.parties.length,0),0),'party rosters');

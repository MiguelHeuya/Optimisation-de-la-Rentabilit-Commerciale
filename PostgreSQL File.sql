

SELECT * FROM superstore;

SELECT COUNT(*) FROM superstore -- Sélectionner toutes les colonnes de la table pour mieux la visualiser dans PgAdmin 4

/* Place à l'analyse exploratoire, pour mieux comprendre notre data set  */
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

/*                      Analyse des dimensions           **********************************    */
/*  ///////////////////////////////////////////////////////////////  */


-- Les différents segments de clients
SELECT "segment" FROM superstore; -- Ceci sélectionne la colonne mais avec des duplications
SELECT DISTINCT("segment") FROM superstore; -- Ceci sélectionne toute les premières occurences de chaque valeur de la colonne
SELECT DISTINCT("customer_name") FROM superstore; -- Tous les noms des clients
SELECT COUNT(DISTINCT("customer_name")) FROM superstore -- Compter tous les noms des clients

-- Interessons nous à la géographie ( On va sélectionner tout ce qui renvoit à un lieu) ------------------
----------------------------------------------------------------------------------------------------------

SELECT DISTINCT("country") FROM superstore; -- Tous les pays
SELECT COUNT(DISTINCT("country")) FROM superstore -- Le nombre de pays

SELECT DISTINCT("region") FROM superstore; -- Toutes les régions
SELECT COUNT(DISTINCT("region")) FROM superstore -- Le nombre de régions

SELECT DISTINCT("state") FROM superstore ; -- Tous les states
SELECT COUNT(DISTINCT("state")) FROM superstore -- Le nombre de states

SELECT DISTINCT("city") FROM superstore ; -- Toutes les cités
SELECT COUNT(DISTINCT("city")) FROM superstore -- Le nombre de cités


-------------------- Intéressons nous  aux produits ----------------
--------------------------------------------------------------------

SELECT DISTINCT("category") FROM superstore; -- Les categories de produits
SELECT DISTINCT("sub-category") FROM superstore; -- Les sous catégories

SELECT COUNT(DISTINCT("product_name")) FROM superstore; -- Sélectionner les noms

-- Ship mode

SELECT DISTINCT("ship_mode") FROM superstore;


----  Analyse des dates order date et ship date ---------------------
--------------------------------------------------------------------

SELECT 'ship_date' as dates, min("ship_date"), max("ship_date") FROM superstore
UNION ALL
SELECT 'order_date', min("order_date"), max("order_date") FROM superstore;


---- Les années de ventes ---------------------
-----------------------------------------------

SELECT 
DISTINCT(EXTRACT(YEAR FROM("order_date"))) as annee 
FROM superstore
ORDER BY 1 asc;


/*  Analysons maintenant les faits  */
/*  ///////////////////////////////////////////////////////////////  */



------------- Analysons les ventes  --------------------
---------------------------------------------------------

SELECT "segment", SUM("sales") as quantite_achetee
FROM superstore
GROUP BY "segment"
ORDER BY SUM("sales") desc
LIMIT 1;   ----- Les segments de clients qui achète le plus


SELECT "region", SUM("sales") as quantite_achetee
FROM superstore
GROUP BY "region"
ORDER BY SUM("sales") desc
LIMIT 1;     ----- La région où on achète le plus


SELECT EXTRACT(YEAR FROM("order_date")), SUM("sales") as ventes
FROM superstore
GROUP BY EXTRACT(YEAR FROM("order_date"))
ORDER BY SUM("sales") desc;      ------- Les classements des années suivant le montant de ventes


------------- Analysons les bénéfices  --------------------
---------------------------------------------------------

SELECT EXTRACT(YEAR FROM("order_date")), SUM("profit") as benefices
FROM superstore
GROUP BY EXTRACT(YEAR FROM("order_date"))
ORDER BY SUM("profit") desc;         ------- Les classements des années suivant le bénéfice réalisé


DROP TABLE IF EXISTS vue

CREATE VIEW vue as (SELECT "product_name", 
SUM("profit")
FROM superstore
GROUP BY "product_name"
ORDER BY SUM("profit") desc
limit 20);      ---------------- Les vingt produits qui font faire le plus de bénéfices


SELECT * FROM vue

SELECT b."product_name",
EXTRACT(YEAR FROM(a."order_date")) as Annee,
SUM(a."profit")
FROM superstore a
INNER JOIN vue b
ON a."product_name" = b."product_name"
GROUP BY (b."product_name", EXTRACT(YEAR FROM("order_date")))
ORDER BY "product_name" desc, SUM("profit") desc; ----------- Ces vingts produits avec leurs années de bénéfices respectifs

/* Ce que j'ai fait ici est très simple, vu que mon but final était d'avoir les 20 produits les plus bénefiques
J'ai d'abord commencé par isolé ces vingts produits dans une vue que j'ai appelée vue et ensuite, j'ai affiché ces
produits avec leurs années et leurs bénéfices avec la table de départ */





/* Place à la modélisation de données  */
------------------------------------------------------------------------------------------------------------
--------------------------------------------------
/* Dans la majorité des cas, il est très rare de tomber sur une seule table de donnée de la sorte
JE PRENDS UN EXEMPLE POUR ILLUSTRER
Lorsque tu te rend dans un site de E-Commerce, tu achète un produit, ils ont réalisé une vente. L'ordinateur enregistrera automatiquement
le montant de la vente, la quantité achetée, la date, le lieu, le bénéfice aussi sera calculé, l'ordinateur va aussi enregistrer
le consommateur, et le produit. 
Maintenant, dans la table de vente, ce sera rare de trouver toutes les informations du consommateur, du produit et meme du lieu
Ce sera plutot les identifiants du client, produit et du lieu qui seront enregistrer.
Et pour avoir par exemple avoir le nom du client, on va se rendre dans une autre table qui contient plus d'information sur le client,
cette table peut etre nommer la table "Client"
Pareil si on veut avoir le nom du produit acheté, on sera rend dans la table "produit".
C'est avantageux en termes de fiabilité et de robutesse.


Ici on aura deux types de tables.
Un type de table de fait et un type de table de dimensions.

La table de fait dans notre cas est la table de ventes, 
Les tables de dimensions sont les tables clients, produits.

La table de fait est la table qui contient les mésures, une mésure est une variable quantitative et qui donne du sens aux 
aggrégations

Une dimension est toute aggrégation qui peut donner du sens aux faits par exemple le nombre.

Par exemple dans notre cas on peut avoir pour fait la quantité, les ventes, les bénéfices.
Et comme dimension on a le nom du produit, le nom du client, le segment du client.


On appelle une telle situation, un modèle en étoile
(Les tables de dimensions sont reliées à la table de fait)
*/


/*    Modélisons cela donc    */

------ Créons la table de dimension "client"  ---------------------
-------------------------------------------------------------------

SELECT * FROM superstore; --- Visualisons la table de fait a nouveau

--- Ici un client est caractérisé par son identifiant (id), son nom et son segment
--- donc la table de dimension client contiendra les colonnes "customer_id", "customer_name", "segment"

SELECT((SELECT COUNT(DISTINCT("customer_id")) FROM superstore) /* Compter le nombre d'id des clients*/ 
- /* Le - représente la différence entre le résultat des deux requetes */ (SELECT COUNT(*)
FROM(
SELECT "customer_id", "customer_name", "segment"
FROM superstore
GROUP BY "customer_id", "customer_name", "segment"
)) /*  Compter le nombre de lignes  */) as nombre_de_id_moins_nombre_de_lignes 

/* Donc ce bloc fait la différence entre le nombre d'id de client et le nombre de ligne de clients pour se rassurer
qu'un id correspond bien à une et une seule ligne. Si le résultat donne 0, c'est le cas, mais si c'est différent de 0
on va devoir fabriquer un id parce que pour notre modèle en étoile les tables doivent etre reliées au moyen des id
Le résultat donne 0, donc pas besoin de fabriquer un id*/


-----    Créer la table "client"  ----------
--------------------------------------------

DROP TABLE IF EXISTS "dim_client" --- Supprimer la table si elle existe

CREATE TABLE "dim_client" AS (SELECT "customer_id", "customer_name", "segment"
FROM superstore
GROUP BY "customer_id", "customer_name", "segment") -- La créer

SELECT * FROM dim_client -- La visualiser


------- Ajout des contraintes d'intégrité -----------
-----------------------------------------------------
ALTER TABLE dim_client
ADD CONSTRAINT pk_dim_client 
PRIMARY KEY (customer_id); -------- La clé primaire est customer_id


ALTER TABLE superstore
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id) 
REFERENCES dim_client(customer_id); ----------- La clé étrangère est customer_id de reférences la table dim_client









------ Créons la table de dimension "produits"  ---------------------
---------------------------------------------------------------------
---------------------------------------------------------------------


SELECT((SELECT COUNT(DISTINCT("product_id")) FROM superstore) /* Compter le nombre d'id des produits*/ 
- /* Le - représente la différence entre le résultat des deux requetes */ (SELECT COUNT(*)
FROM(
SELECT "product_id", "category", "sub-category", "product_name"
FROM superstore
GROUP BY "product_id", "category", "sub-category", "product_name"
))) as difference

/* Donc ce bloc fait la différence entre le nombre d'id des produits et le nombre de ligne de produits pour se rassurer
qu'un id correspond bien à une et une seule ligne. Si le résultat donne 0, c'est le cas, mais si c'est différent de 0
on va devoir fabriquer un id parce que pour notre modèle en étoile les tables doivent etre reliées au moyen des id
Le résultat donne ne donne pas 0, donc on va devoir fabriquer un id.
Pour ce faire on ne sélectionnera pas tout simplement le "product_id"*/


ALTER TABLE superstore
DROP COLUMN product_id CASCADE;  -- Suppression de la colonne product_id dans la table superstore

-------------------------------------
/*  Créons donc cette table de dimension produits qu'on va appeler "dim_product" */
--------------------------------------

DROP TABLE IF EXISTS "dim_product" --- Supprimer la table au cas où elle existe

CREATE TABLE "dim_product" AS(
SELECT "category", "sub-category", "product_name"
FROM superstore
GROUP BY "category", "sub-category", "product_name"
)  --- Créer la table

SELECT * FROM dim_product --- Visualiser la table

ALTER TABLE dim_product 
ADD COLUMN product_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY --- Création de l'id pour la table dim_product

SELECT * FROM dim_product --- Visualiser la table après l'ajout de l'index


/*  Intégration de la colonne product_id dans la table superstore  */

ALTER TABLE superstore 
ADD COLUMN product_id INT;   --- Création de la colonne product_id dans la table superstore


UPDATE superstore s
SET product_id = p.product_id
FROM dim_product p
WHERE s."category" = p."category" 
  AND s."sub-category" = p."sub-category" 
  AND s."product_name" = p."product_name";   --- Remplissage de la colonne product_id dans la table superstore
  										 --- suivant les valeurs des autres colonnes de la table dim_product


-- On rend la colonne obligatoire (si toutes les lignes ont été matchées)
ALTER TABLE superstore ALTER COLUMN product_id SET NOT NULL;

-- On crée la contrainte de clé étrangère
ALTER TABLE superstore 
ADD CONSTRAINT fk_product 
FOREIGN KEY (product_id) 
REFERENCES dim_product (product_id);


----- Vérifions bien que la colonne a convenablement été matché dans la table de fait

SELECT((SELECT COUNT(DISTINCT("product_id")) FROM dim_product) /*Compter les id dans la table dim_product*/
- 
(SELECT COUNT(DISTINCT("product_id")) FROM superstore) /*Compter les id dans la table superstore*/
) as difference_entre_les_id 

/*Les id sont bien en meme nombre dans les deux colonnes*/

SELECT((SELECT COUNT(DISTINCT("product_id")) FROM dim_product) /*Compter les id dans la table dim_product*/
- (SELECT COUNT(*) FROM(SELECT 
a."category" as categorie_de_superstore, 
b."category" as categorie_de_dim_product, 
a."sub-category" as sub_category_de_superstore,
b."sub-category" as sub_category_de_dim_product, 
a."product_name" as product_name_de_superstore,
b."product_name" as product_name_de_dim_product
FROM superstore a
LEFT JOIN dim_product b
ON a."product_id" = b."product_id"
GROUP BY a."category", b."category", a."sub-category", b."sub-category", a."product_name", b."product_name"))) 
AS difference


/*  Ce bloc réuni chacunes des trois colonnes de chacune des deux tables dans une meme table.
Elle compte le nombre de ligne avant de soustraire ce nombre au nombre d'id de la table id
Si la colonne product_id a bien été matchée dans la colonne superstore, category de dim_product sera pareil à category
de superstore pareil pour les colonnes sub-category et product_name
Si c'est bien le cas le nombre de ligne de la requete réunissant ces six colonnes sera le meme que le nombre de ligne 
de la table dim_product qui est déjà égal au nombre d'id de la table dim_product
Donc en fesant la différence entre le nombre de lignes composées des six colonnes, au nombre d'index, la différnce
doit donner 0
Si c'est le cas, la colonne a bien été matchée*/





----------------------------------------------------------------------
/*      Création de la table de dimension géographic        */
-----------------------------------------------------------------------
/*   Il y a pas d'id pour lieu ici donc à nous d'en fabrique   */




DROP TABLE IF EXISTS "dim_geographic" --- Supprimer la table au cas où elle existe

CREATE TABLE "dim_geographic" AS(
SELECT "country", "region", "state", "city", "postal_code"
FROM superstore
GROUP BY "country", "region", "state", "city", "postal_code"
)  --- Créer la table

SELECT * FROM dim_geographic --- Visualiser la table

ALTER TABLE dim_geographic 
ADD COLUMN geographic_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY --- Création de l'id pour la table dim_geographic

SELECT * FROM dim_geographic --- Visualiser la table après l'ajout de l'index


ALTER TABLE superstore 
ADD COLUMN geographic_id INT;   --- Création de la colonne geographic_id dans la table superstore


UPDATE superstore r
SET geographic_id = t.geographic_id
FROM dim_geographic t
WHERE r."country" = t."country" 
  AND r."region" = t."region" 
  AND r."state" = t."state"
  AND r."postal_code" = r."postal_code";   --- Remplissage de la colonne geographic_id dans la table superstore
  										 --- suivant les valeurs des autres colonnes de la table dim_geographic


-- On rend la colonne obligatoire (si toutes les lignes ont été matchées)
ALTER TABLE superstore ALTER COLUMN geographic_id SET NOT NULL;

-- On crée la contrainte de clé étrangère
ALTER TABLE superstore 
ADD CONSTRAINT fk_geographic 
FOREIGN KEY (geographic_id) 
REFERENCES dim_geographic (geographic_id);




/*   Vérifions si ces requetes ont bien été matchée    */
------------------ Meme test que précédemment -------------------------


SELECT((SELECT COUNT(DISTINCT("geographic_id")) FROM dim_geographic) /*Compter les id dans la table dim_product*/
- (SELECT COUNT(*) FROM(SELECT 
a."country" as categorie_de_superstore, 
b."country" as categorie_de_dim_product, 
a."state" as sub_category_de_superstore,
b."state" as sub_category_de_dim_product, 
a."region" as product_name_de_superstore,
b."region" as product_name_de_dim_product,
a."city" as product_name_de_superstore,
b."city" as product_name_de_dim_product,
a."postal_code" as product_name_de_superstore,
b."postal_code" as product_name_de_dim_product
FROM superstore a
LEFT JOIN dim_geographic b
ON a."geographic_id" = b."geographic_id"
GROUP BY a."country", b."country", a."state", b."state", a."region", b."region", a."city", b."city", a."postal_code", b."postal_code"))) 
AS difference





-------------------------------------------------------------------------------------------------
----------------------/*Création de la table de dimension dates*/--------------------------------
--------------------------------------------------------------------------------------------------


CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    annee INT,
    mois_numero INT,
    mois_nom VARCHAR(20),
    trimestre VARCHAR(5),
    jour_semaine_numero INT,
    jour_nom VARCHAR(20)
);  ---------------------- Définition des colonnes ainsi que de leurs types



SELECT 'order_date' as type_date, MIN("order_date"), MAX("order_date") FROM fact_sales
UNION ALL
SELECT 'ship_date', MAX("ship_date"), MAX("ship_date") FROM fact_sales
--- Vérifier le minimum et le maximum de chaque date pour savoir comment insérer les sates



INSERT INTO dim_date (date_id, annee, mois_numero, mois_nom, trimestre, jour_semaine_numero, jour_nom)
SELECT 
datum AS date_id,
EXTRACT(YEAR FROM datum) AS annee,
EXTRACT(MONTH FROM datum) AS mois_numero,
-- Nom du mois (ex: Janvier)
TO_CHAR(datum, 'TMMonth') AS mois_nom,
-- Format Q1, Q2, etc.
'Q' || TO_CHAR(datum, 'Q') AS trimestre,
-- Jour de la semaine (1 pour Lundi, conformément à votre DAX)
EXTRACT(ISODOW FROM datum) AS jour_semaine_numero,
-- Nom du jour (ex: Lundi)
TO_CHAR(datum, 'TMDay') AS jour_nom
FROM generate_series(
'2010-01-01'::DATE, 
'2030-12-31'::DATE, 
'1 day'::INTERVAL
) AS datum;          ---------------------- Remplissage des colonnes




SELECT * FROM dim_date






--------------------------------------------------------
---- Suppression des colonnes des tables de dimensions dans la tables de faits
---------------------------------------------------------------------------------

ALTER TABLE superstore
	DROP COLUMN "customer_name" CASCADE,
	DROP COLUMN "segment" CASCADE,
	DROP COLUMN "product_name" CASCADE,
	DROP COLUMN "category" CASCADE,
	DROP COLUMN "sub-category" CASCADE,
	DROP COLUMN "row_id" CASCADE,
	DROP COLUMN "order_id" CASCADE
	DROP COLUMN "country",
	DROP COLUMN "region",
	DROP COLUMN "state",
	DROP COLUMN "city",
	DROP COLUMN "postal_code"
	DROP COLUMN "ship_mode";
	
ALTER TABLE superstore 
RENAME TO fact_sales;

SELECT * FROM fact_sales


/*     -----------   Diviser la colonne profit en deux, entre les colonnes positive profit et negative profit 
pour séparer les gains des pertes*/
------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

ALTER TABLE superstore
	RENAME COLUMN "profit" TO "total_profit"

SELECT * FROM superstore

-------------------------------- Création des colonnes positf_profit et negatif_profit  -------------------------
-----------------------------------------------------------------------------------------------------------------

ALTER TABLE fact_sales
ADD COLUMN positif_profit NUMERIC,
ADD COLUMN negatif_profit NUMERIC;


---------------------  Remplissage de ces colonnes ---------------------------------------
------------------------------------------------------------------------------------------

UPDATE fact_sales
SET 
positif_profit = CASE 
WHEN total_profit > 0 THEN total_profit 
ELSE 0 
END,
negatif_profit = CASE 
WHEN total_profit < 0 THEN total_profit 
ELSE 0 
END;




/*----------------------------      On remplit ces colonnes de la sorte:          ----------------------------------------*/
/*  Si total_profit est negatif, negatif_profit prend sa valeur et positif_profit prend la valeur 0 et si total_profit
 est positif, positif_profit prend sa valeur et negatif_profit prend la valeur 0.
 Dans chaque ligne positif_profit + negatif_profit = total_profit*/




SELECT * FROM fact_sales -- Table de fait final

SELECT * FROM dim_client -- Table de dimension client

SELECT * FROM dim_product -- Table de dimension produit

SELECT * FROM dim_geographic -- Table de dimension geographic

SELECT * FROM dim_date -- Table de dimension date






/* Maintenant notre table de fait contient uniquement des faits ( des chiffres ) et des IDs (Identifiants) ce qui
est le mieux adapté
Et nos tables de dimensions contiennent les informations qui peuvent donner du sens au faits*/



/* Les tables sont maintenant pretes pour etre connectées à PowerBI*/















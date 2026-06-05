"""
============================================================================
NOM DU PROGRAMME : Importateur Automatique de Ventes
OBJECTIF         : Lire un fichier Excel/CSV de ventes, le nettoyer proprement 
                   et l'enregistrer automatiquement dans la base de données centrale.
============================================================================
"""

import os
import pandas as pd
from sqlalchemy import create_engine

# --- ÉTAPE 1 : SÉCURISATION DES ACCÈS ---
# Pour éviter que n'importe qui puisse voir les mots de passe du serveur,
# le programme récupère les codes d'accès de manière masquée et sécurisée.
NOM_UTILISATEUR = os.getenv('DB_USER', 'postgres')          
MOT_DE_PASSE = os.getenv('DB_PASSWORD', 'ton_mot_de_passe') 
ADRESSE_SERVEUR = os.getenv('DB_HOST', 'localhost')
PORT_SERVEUR = os.getenv('DB_PORT', '5432')
NOM_BASE_DONNEES = os.getenv('DB_NAME', 'MonEntrepotDeDonnees')

# Assemblage de l'adresse de connexion sécurisée
LIEN_CONNEXION = f"postgresql://{NOM_UTILISATEUR}:{MOT_DE_PASSE}@{ADRESSE_SERVEUR}:{PORT_SERVEUR}/{NOM_BASE_DONNEES}"

try:
    # --- ÉTAPE 2 : OUVERTURE DE LA PASSERELLE ---
    # On prépare la passerelle informatique qui va lier ce script à la base de données.
    moteur_connexion = create_engine(LIEN_CONNEXION)

    # --- ÉTAPE 3 : LECTURE DU FICHIER (Extraction) ---
    # Le programme ouvre et lit le fichier brut contenant toutes les ventes de l'entreprise.
    print("⏳ Lecture du fichier des ventes en cours...")
    tableau_ventes = pd.read_csv('Superstore.csv', encoding='latin-1')

    # --- ÉTAPE 4 : MISE EN FORME ET NETTOYAGE (Transformation) ---
    print("🛠️ Nettoyage et uniformisation des données...")
    
    # Règle A : On force l'ordinateur à comprendre les colonnes de dates comme de vraies dates sur le calendrier.
    # Cela évite que le système inverse les jours et les mois par erreur.
    tableau_ventes["Ship Date"] = pd.to_datetime(tableau_ventes["Ship Date"], format='mixed')
    tableau_ventes["Order Date"] = pd.to_datetime(tableau_ventes["Order Date"], format='mixed')
    
    # Règle B : Standardisation des titres de colonnes. 
    # Pour éviter les bugs informatiques, on transforme tous les titres en minuscules 
    # et on remplace les espaces vides par des tirets bas '_'. 
    # Exemple : "Ship Date" devient "ship_date".
    tableau_ventes.columns = tableau_ventes.columns.str.replace(' ', '_').str.lower()

    # --- ÉTAPE 5 : ENREGISTREMENT EN BASE DE DONNÉES (Chargement) ---
    print("🚀 Sauvegarde des données propres dans la base centrale...")
    
    # On ouvre la porte de la base de données, on y dépose le tableau propre, puis on referme à clé.
    with moteur_connexion.begin() as connexion_active:
        # 'if_exists=replace' : Si une ancienne version du tableau existe, on l'écrase pour mettre la nouvelle à jour.
        # 'index=False' : On supprime les numéros de lignes temporaires inutiles.
        tableau_ventes.to_sql(
            name='superstore', 
            con=connexion_active, 
            if_exists='replace', 
            index=False,
            method='multi'   # Technique pour envoyer les données très rapidement par paquets
        )
        
    print("✅ Opération réussie ! Les données sont prêtes et la connexion est fermée.")

except Exception as e:
    # Si une panne survient (coupure réseau, fichier manquant...), le programme affiche une alerte claire au lieu de planter.
    print(f"❌ L'importation a échoué. Cause de l'erreur : {e}")

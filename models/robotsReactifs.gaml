model robotsReactifs
/*Les variables globales et méthodes */
global{
	int nb_colonnes <- 10;
	int nb_lignes <- 10;
	int nb_robots <- 10; // Nombre de robots initial
	int nb_agents <- 20; // Nombre de minerais initial
	int nb_agents_restants <- nb_agents ; // Nombre de minerais restants = Nombre de minerais initial au début
	int nb_agents_deposes<- 0; // Nombre de minerais deposés dans la base
	int nb_robots_portant <- 0 ; // Nombre de robots portant un minerai
	environnement base <- environnement[0,0];
	file robot_mineur1 <- image_file("../images/robot_mineur.png");
	file robot_mineur2 <- image_file("../images/robot_mineur3.png");
	file mine <- image_file("../images/or.jpg");
	/* Initialisation */
	init {
		create robot_mineur number: nb_robots ;
		create minerai number: nb_agents ;
	}
	/* Arret de la simulation */
	reflex finSimulation when: nb_agents_deposes = nb_agents{
		do pause;
	}
	//Ecriture des resultats
	reflex EcrireResultat {
		save [cycle, nb_agents_restants, nb_robots_portant, nb_agents_deposes]
		type: csv to: "result.csv";
	}
}

/* Grille de l'environnement */
grid environnement width: nb_colonnes height: nb_lignes neighbors: 4 {
	list<environnement> voisins <- (self neighbors_at 2);
}
/* Définition de l'agent robot_mineur */
species robot_mineur {
	int porte <- 0; // variable pour vérifier si l'agent porte ou non un minerai
	environnement position <- one_of (environnement) ; // position du robot
	list<minerai> mines update: minerai inside (position); // liste des mines ramassés par le robot
	minerai mine; // le minerai porté par le robot	
	/*Initialisation de la position du robot dans l'environnemnt */
	init {
		location <- position.location;
	}
	/* Aspect d'un robot_mineur */
	aspect aspect_robot{
		if(porte = 0){
			draw robot_mineur1 size: 15;
		}
		else{
			draw robot_mineur2 size: 10;
		}	
	}
	/* Definition de la fonction de deplacement du robot */
	reflex basic_move {
		position <- one_of (position.voisins);
		location <- position.location ;
	}
	/* Definition de la fonction porterMine */
	reflex porterMine when: porte = 0 {
		if (empty(mines)) {
			porte <- 0;
		} else {
			mine<-one_of(mines);
			if(mine.recuperer=false){
				porte <- 1;
				mine.recuperer<-true;
				nb_agents_restants <- nb_agents_restants-1;
				nb_robots_portant <- nb_robots_portant + 1;
			}
		}
	}
	/* Definition de la fonction deplacer Mine */
	reflex deplacerMine when: porte = 1{
		position<-one_of (position.voisins );
		location <- any_location_in(position);
		mine.location <-location;
	}
	/* Definition de la fonction deposerMine dans la base */
	reflex deposerMine when: position = base {
		if(porte = 1){
			porte <- 0;
			nb_agents_deposes <- nb_agents_deposes + 1;
			nb_robots_portant <- nb_robots_portant-1;
		}
	}
}
/* Definition de l'objet minerai */
species minerai {
	bool recuperer <- false; // variable qui montre si le minerai est recuperere ou non
	environnement position <- one_of (environnement) ; // position d'un minerai
	/* fonction d'initialisation de la position d'un minerai */
	init {
		location <- position.location;
	}
	/* Definition de l'aspect de la mine */
	aspect default {
		//draw circle(1)color: #yellow;
		draw mine size: 2;
	}
}

/* La simulation */
experiment robot type: gui {
	parameter "Nombre de lignes" var: nb_lignes;
	parameter "Nombre de colonnes" var: nb_colonnes;
	parameter "Nombre de robots mineurs" var: nb_robots;
	parameter "Nombre de minerais" var: nb_agents;
	output {
		display main_display{
			grid environnement;
			species robot_mineur aspect: aspect_robot ;
			species minerai aspect: default ;
		}
		//Evolution
		display diagramme_circulaire{
			chart "my_chart" type:pie {
                data "Nombre de minerais initial" value:nb_agents color:#red;
                data "Nombre de minerais déposés" value:nb_agents_deposes color:#blue;
				data "Nombre de minerais restants" value:nb_agents_restants color:#yellow;
            }
		}
		
		display graphe{
			chart "my_chart" type:series {
                data "Nombre de minerais initial" value:nb_agents color:#red;
                data "Nombre de minerais déposés" value:nb_agents_deposes color:#blue;
				data "Nombre de minerais restants" value:nb_agents_restants color:#yellow;
            }
		}
		monitor "Temps " value:cycle;	
	}
}
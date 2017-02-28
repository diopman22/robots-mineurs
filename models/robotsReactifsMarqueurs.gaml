/**
* Name: robotsReactifs
* Author: Mansour
* Description: 
* Tags: Tag1, Tag2, TagN
*/

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
	point p_base <- {0,0};
	float evaporation_trace <- 1.0 min: 0.0 max: 240.0 parameter: 'Evaporation des traces' ;
	float difusion_trace <- 1.0 min: 0.0 max: 1.0 parameter: 'Diffusion des traces:' ;
	int grid_frequency <- 1 min: 1 max: 100 parameter: 'Mise a jour de lenvironnement apres:';
	float grid_transparency <- 3.0;
	//background road
	rgb background const: true <- rgb(#yellow);
	
	/* Initialisation */
	init {
		create robot_mineur number: nb_robots ;
		create minerai number: nb_agents ;
	}
	//Reflexion qui permet de degager les traces a la prise dun monerai
	reflex diffuse {
 		diffuse var:road on:environnement proportion: difusion_trace radius:3 propagation: gradient method:convolution;
   	}
	
	/* Arret de la simulation */
	reflex finSimulation when: nb_agents_deposes = nb_agents{
		do pause;
	}
	
}

/* Grille de l'environnement */
grid environnement width: nb_colonnes height: nb_lignes neighbors: 4 {
	list<environnement> voisins <- (self neighbors_at 2);
	bool is_nest const: (self distance_to p_base < 4) ? true : false;
	float road <- 0.0 max: 240.0 update: (road <= evaporation_trace) ? 0.0 : road - evaporation_trace;
}

/* Définition de l'agent robot_mineur */
species robot_mineur {
	int porte <- 0; // variable pour vérifier si l'agent porte ou non un minerai
	environnement position <- one_of (environnement) ; // position du robot
	list<minerai> mines update: minerai inside (position); // liste des mines ramassés par le robot
	minerai mine; // le minerai porté par le robot
	float pr <- (environnement(location)).road;
	
	/*Initialisation de la position du robot dans l'environnemnt */
	init {
		location <- position.location;
	}
	/* Aspect d'un robot_mineur */
	aspect aspect_robot{
		if(porte = 0){
			draw circle(3) color:#green;
		}
		else{
			draw circle(3) color:#blue;
		}	
	}
	/* Definition de la fonction de deplacement du robot */
	reflex basic_move {
		position <- one_of (position.voisins);
		location <- position.location ;
		pr <- (environnement(location)).road;
	}
	reflex diffuse_road when: porte=1{
		environnement(location).road <- environnement(location).road + 100.0;
	}
	point point_suivant {
		container list_places <- environnement(location).neighbors;
		if (list_places count (nb_agents_restants > 0)) > 0 {
			return point(list_places first_with (nb_agents_restants > 0));
		} else {
			list_places <- (list_places where ((each.road > 0) and ((each distance_to base) > (self distance_to base)))) sort_by (each.road);
			return point(last(list_places));
		}
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
	reflex deplacerMine when: porte = 1 or ((pr > 0.05) and (pr < 4)){
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
		draw circle(1)color: #yellow;
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
		
		monitor "Temps " value:cycle;	
	}
}
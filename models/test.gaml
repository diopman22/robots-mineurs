model robot
/* Insert your model definition here */
global {
	float evaporation_trace <- 1.0 min: 0.0 max: 240.0 parameter: 'Evaporation des traces' ;
	float difusion_trace <- 1.0 min: 0.0 max: 1.0 parameter: 'Diffusion des traces:' ;
	int gridsize <- 100 parameter: 'Taille de lenviroennement:';
	int nb_robots <- 30;
	// frequence de mise a jour de lenvironnement
	int grid_frequency <- 1 min: 1 max: 100 parameter: 'Mise a jour de lenvironnement apres:';
	int nb_minerais <- 5;
	int cpt_minerai <- 0;
	float grid_transparency <- 3.0;
	//definition de la base
	point base const: true <- { 5, 17 };
	int minerai_capture <- 1;
	//background road
	rgb background const: true <- rgb(#yellow);
	rgb minerai_color const: true <- rgb(#black);
	//background base
	rgb nest_color const: true <- rgb(#yellow); 
	init {
		// creation des minerai
		create minerai;
		//creation des robots
		create robot number: nb_robots;
	}
	//Reflexion qui permet de degager les traces a la prise dun monerai
	reflex diffuse {
      diffuse var:road on:environnement proportion: difusion_trace radius:3 propagation: gradient method:convolution;
   }
   reflex arret when: cpt_minerai = nb_minerais{
   		do pause;
   }
}
// Environement
grid environnement width: gridsize height: gridsize neighbors: 8 frequency: grid_frequency use_regular_agents: false use_individual_shapes: false{
	bool is_nest const: true <- (topology(environnement) distance_between [self, base]) < 4;
	float road <- 0.0 max: 240.0 update: (road <= evaporation_trace) ? 0.0 : road - evaporation_trace;
	rgb color <- is_nest ? nest_color : ((mine > 0) ? minerai_color : ((road < 0.001) ? background : rgb(#009900) + int(road * 5))) update: is_nest ? nest_color : ((mine > 0) ?
	minerai_color : ((road < 0.001) ? background : rgb(#000000) + int(road * 5)));
	int mine <- 0;
}

//agent robot
species robot skills:[moving]  control: fsm{
	
		bool porteur <- false;
		environnement position <- one_of (environnement) ; // position du robot
		/*Initialisation de la position du robot dans l'environnemnt */
		init {
			location <- position.location;
		}
		// comportement permettant de laisser des traces a la saisie dun minerai
		reflex diffuse_road when: porteur=true{
		 environnement(location).road <- environnement(location).road + 100.0;
		}
		point point_suivant {
			container list_places <- environnement(location).neighbors;
			if (list_places count (each.mine > 0)) > 0 {
				return point(list_places first_with (each.mine > 0));
			} else {
				list_places <- (list_places where ((each.road > 0) and ((each distance_to base) > (self distance_to base)))) sort_by (each.road);
				return point(last(list_places));
			}
		}	
		state wandering initial: true {
			do wander amplitude:20;
			float pr <- (environnement(location)).road;
			transition to: transporter when: porteur=true;
			transition to: suivre_trace when: (pr > 0.05) and (pr < 4);	
		}
		state wandering2 {
			do wander amplitude:20;
		}
		//Etat de transport du minerai
		state transporter {
			do goto(target: base);
			transition to: wandering when: porteur=false{
				do a;
			}	
		}
		action a {
			cpt_minerai <- cpt_minerai+1;
		}
		//Etat permettant de suivre les traces des autres robots
		state suivre_trace {
			point next_place <- point_suivant();
			float pr <- (environnement(location)).road;
			location <- next_place;
			transition to: transporter when: porteur=true;
			transition to: wandering when: (pr < 0.05) or (next_place = nil);
		}
		action deposer_minerai {
			minerai_capture <- minerai_capture + 1;
			porteur <- false;
			heading <- heading - 180;
		}
		reflex prendre_minerai when: porteur=false and (environnement(location)).mine > 0 {
			porteur <- true;
			environnement place <- environnement(location);
			place.mine <- place.mine - 1;		
		}	
		//Reflexe de deposer le minerai a la base
		reflex deposer_minerai when: porteur=true and (environnement(location)).is_nest {
			do deposer_minerai();
		}
	aspect default {
		if(porteur = false){
			draw circle(1) color:#green;
		}
		else{
			draw circle(1) color:#yellow;
		}	
	}
}
// agent minerai
species minerai {
	init {
		loop times: nb_minerais {
			point loc <- { rnd(gridsize - 10) + 5, rnd(gridsize - 10) + 5 };
			list<environnement> minerai_places <- one_of(environnement);
			ask minerai_places {
				if mine = 0 {
					mine <- 1;
					minerai_places <- minerai_places + 1;
					color <- minerai_color;  
				}                                           
			}
		}
	}
	
}

// simulation
experiment exp type: gui {
	parameter 'Nombre de robots:' var: nb_robots  ;
	parameter 'Nombre de minerais:' var: nb_minerais ;

	output {
		display Robot_Simulation {
			agents "agents" transparency: 0.7 position: { 0.05, 0.05 } size: { 1.0, 1.0 } value: (environnement as list) where ((each.mine > 0) or (each.road > 0) or (each.is_nest)) ;
			species robot position: { 0.05, 0.05 }  aspect: default;		
		}
		monitor "Temps " value:cycle;
	}	
}


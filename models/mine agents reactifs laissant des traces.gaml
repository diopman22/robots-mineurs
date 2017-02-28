/**
* Name: mine
* Author: Light
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model minereactifprimitif
global{
	//Nombre de robots
	int recolte;
	int nombre_de_robots <-3  min: 1 max: 2000 ;
	int nombre_de_minerais <-15  min: 1 max: 2000 ;
	int nbm;
	bool use_icons <- true ;
	bool display_state <- true;
	int nb0;
	//Taille de la grille
	int gridsize <- 100 ;
	//Centre de la grille sera utilisé comme base de minerais
	point centre const: true <- { (gridsize / 2),  (gridsize / 2)} ;
	point pointDepart const: true <- { (gridsize / 2)-5,  (gridsize / 2)-4} ;
	string _robot_libre const: true <- '../images/robot_libre.jpg' ;
	string _robot_charge const: true <- '../images/robot_charge.jpg'  ;
	string _base const: true <- '../images/minerai.jpg'  ;
	int mineraisRecoltes <- 0 ;    
	
	geometry shape <- square(gridsize);
	init{  
		//Creation et placement des robots de manière aléatoire
		create robot number: nombre_de_robots with: [location::any_location_in (environnement({rnd(75),rnd(75)}))] ;
		create minerai number: nombre_de_minerais with: [location::any_location_in (environnement({rnd(75),rnd(75)}))] ;
		create base number: 1 with: [location::centre] ;
		create marque number: 1 with: [location::centre, expire::true];
		
		nbm<-nombre_de_minerais;
	}

}
//Grille de l'environnement
grid environnement width: 20 height: 20 neighbors: 8 use_regular_agents: false {
	list<environnement> neighbours <- self neighbors_at 8;
	bool estLaBase <- (self distance_to centre) < 4 ;
	
}
//Le Minerai
species minerai skills: [moving] control: fsm {
	bool ramasse <-false;
	environnement place update: environnement (location ); 
	//L'aspect de mon minerai
	aspect imageMinerai{
		if(!ramasse){
			draw circle(1.0) empty: false color: rgb ('yellow') ;
		}else{
		}
	}
	//Se deplacer
	state immobiliser initial: true { 
		transition to: regagnerBase when: (((robot(location) distance_to minerai(location))<1) and !(robot(location).aMinerai)){
		ramasse<-true;
		}
	}
	state regagnerBase { 
		do goto target:centre speed:0.05;
	}
}

//La Base
species base skills: [] control: fsm {
	bool vide <-true;
	environnement place update: environnement (location ); 
	//L'aspect de ma base
	aspect imageBase{
		if(!vide){
			draw circle(8.0) empty: false color: rgb ('grey') ;
			draw circle(1.0) empty: false color: rgb ('yellow') ;
		}else{
			draw square(20.0) empty: false color: rgb ('grey');
		}
	}
}
//La marque
species marque control:fsm{
			bool expire<-false;
			bool aExpire<-false;
			robot generateur;
			int idMarque;
			environnement place update: environnement (location); 
			//L'aspect de ma marque
			aspect textMarque{
			
				if(!aExpire){
					draw cross(1.0) empty: false color: rgb ('purple');
				}else{
					
				}
			}
			state immobile initial:true{
				transition to: mourir when:((cycle mod 10000)=0); 
			}
			state mourir{
				//aExpire<-true;
			}
			
			
		}	
//Le robot
species robot skills: [moving] control: fsm {
	float vitesse <- 0.25 ;
	robot birthmarkGen;
	marque lastSeenMark;
	marque nextMark;
	environnement place update: environnement (location ); 
	string im <- 'robot_libre' ;
	string statut;
	bool aMinerai <- false ;
	int nbMarquesRestantes <- 20;
	//Se deplacer
	state deplacer initial: true { 
		do wander amplitude:5 speed:0.05;
		transition to:joindrePremiereMarque when:(((robot(location) distance_to minerai(location))<1)and ((robot(location) distance_to centre>1)) and !aMinerai and !(minerai(location).ramasse)){
			birthmarkGen<-marque(location).generateur;
		}
		
	}
	state immobiliser{
		
	}
	state joindreAutresMarques{
		do goto target: lastSeenMark.location speed:0.05;
		//do wander amplitude:5 speed:0.05;
		if((cycle mod 100)=0)and (nbMarquesRestantes!=0){
			create marque number: 1 with: [location::point(robot(location)), expire::true, generateur::self, idMarque::nbMarquesRestantes,color::rnd(100)];
			nbMarquesRestantes <- nbMarquesRestantes-1;
		}
		transition to: deplacer when: ((robot(location) distance_to base(location))<10){
			if(aMinerai){
				mineraisRecoltes<-mineraisRecoltes+1;
				aMinerai<-false;	
			}
			if(mineraisRecoltes=nombre_de_minerais){
				ask world{
					do pause;	
				}	
			}
		}
		transition to:joindreAutresMarques when:(((robot(location) distance_to lastSeenMark)<10) and (lastSeenMark.generateur=birthmarkGen) and (lastSeenMark.idMarque>=1)){
			if !(empty((marque.population where ((each.idMarque=lastSeenMark.idMarque-1)and(each.generateur=birthmarkGen))))){
				nextMark<-(marque.population where ((each.idMarque=lastSeenMark.idMarque-1)and(each.generateur=birthmarkGen)))[0];			
				write('lastSeenMark: '+lastSeenMark+' id: '+lastSeenMark.idMarque+ ' dist: '+robot(location) distance_to lastSeenMark);
				lastSeenMark<-nextMark;	
			}else{
				write('empty');
			}
			
			
		}
		transition to:deplacer when:((empty((marque.population where ((each.idMarque=lastSeenMark.idMarque-1)and(each.generateur=birthmarkGen)))))){
			write('moving on');
		}
	}
	state joindrePremiereMarque{
		statut <- 'charge';
		aMinerai<-true;
		do wander amplitude:5 speed:0.05;
		if((cycle mod 100)=0)and (nbMarquesRestantes!=0){
			create marque number: 1 with: [location::point(robot(location)), expire::true,generateur::self, idMarque::nbMarquesRestantes,color::rnd(100)];
			nbMarquesRestantes <- nbMarquesRestantes-1;
		}
		transition to:joindreAutresMarques when:((robot(location) distance_to marque(location))<1 and (marque(location).generateur!=self)){
			lastSeenMark<-marque(location);
			birthmarkGen<-marque(location).generateur;
		}
		transition to: deplacer when: ((robot(location) distance_to base(location))<10){
			
			lastSeenMark<-marque(centre);
			if(aMinerai){
				mineraisRecoltes<-mineraisRecoltes+1;
				aMinerai<-false;	
			}
			
			if(mineraisRecoltes=nombre_de_minerais){
				ask world{
					do pause;	
				}	
			}
		}
	}
	
	action saisir {
	}
	//L'aspect de mon robot
	aspect imageRobot {
		if(!aMinerai){
			statut<-'libre';
			draw file(_robot_libre) rotate: heading at: location size: {8,5} ;	
		}else{
			statut<-'charge';
			draw file(_robot_charge) rotate: heading at: location size: {8,5} ;
		}
	}
	aspect text {
		if(!aMinerai){
			statut<-'libre';
			draw circle(1.0) empty: false color: rgb ('green') ;	
		}else{
			statut<-'charge';
			draw circle(1.0) empty: false color: rgb ('orange') ;
		}
		draw statut at: location + {-3,1.5} color: °black font: font("Helvetica", 14 * #zoom, #plain) perspective:true;
	}           
		//Une marque
}

experiment simulation1 type: gui {
	
	parameter 'Nombre de robots:' var: nombre_de_robots category: 'Model' ;
	init {
		
	}
	
	output {
		display robot  {
			grid environnement lines:#black;
			species robot aspect: imageRobot ;
			species minerai aspect: imageMinerai ;
			species base aspect: imageBase;
			species marque aspect: textMarque;
		}
	}
	
	
	permanent {
		display Comparison background: #white {
			chart "Nombre de minerais" type: series {
					data "Minerais restants "  value: nombre_de_minerais-mineraisRecoltes color: #blue marker: false style: line;
					data "Minerais recueillis "  value: mineraisRecoltes color:#yellow marker: false style: line ;
					
			}
			
		}
	}
}
//Organism

package conv.chadxtogame;

import java.util.*;

public class Organism extends FeatSub {

private String m_genus;
private String m_species;
private String m_taxgroup;

	public Organism(String the_id){
		super(the_id);
	}

	public void setgenus(String the_genus){
		m_genus = the_genus;
	}

	public String getgenus(){
		return m_genus;
	}

	public void setspecies(String the_species){
		m_species = the_species;
	}

	public String getspecies(){
		return m_species;
	}

	public void settaxgroup(String the_taxgroup){
		m_taxgroup = the_taxgroup;
	}

	public String gettaxgroup(){
		return m_taxgroup;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"Organism:");
		System.out.println(offsetTxt+"  genus     <"+m_genus+">");
		System.out.println(offsetTxt+"  species   <"+m_species+">");
		System.out.println(offsetTxt+"  taxgroup  <"+m_taxgroup+">");
	}
}


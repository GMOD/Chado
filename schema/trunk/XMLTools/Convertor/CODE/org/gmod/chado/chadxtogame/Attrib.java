//GENFEAT

package org.gmod.chado.chadxtogame;

public class Attrib {
public String m_Id = null;

	public Attrib(String the_Id){
		m_Id = the_Id;
	}

	public void setId(String the_Id){
		m_Id = the_Id;
	}

	public String getId(){
		return m_Id;
	}

	public void Display(int the_depth){
		if(this instanceof CV){
			((CV)this).Display(the_depth);
		}else if(this instanceof CVTerm){
			((CVTerm)this).Display(the_depth);
		}else if(this instanceof Dbxref){
			((Dbxref)this).Display(the_depth);
		//}else if(this instanceof FeatProp){
		//	((FeatProp)this).Display(the_depth);
		}else if(this instanceof Organism){
			((Organism)this).Display(the_depth);
		}else if(this instanceof Pub){
			((Pub)this).Display(the_depth);
		}else if(this instanceof Synonym){
			((Synonym)this).Display(the_depth);
		}
	}
}


//CVTerm
package conv.chadxtogame;

import java.util.*;

public class CVTerm extends FeatSub {

private SMTPTR m_CVId = new SMTPTR("cv");
private String m_name = null;

	public CVTerm(String the_id){
		super(the_id);
	}

	public void setCVId(String the_CVId){
		m_CVId.setkey(the_CVId);
	}

	public void setCVId(FeatSub the_gf){
		m_CVId.setGF(the_gf);
	}

	public void setCVId(SMTPTR the_SMTPTR){
		m_CVId = the_SMTPTR;
	}

	public String getCVId(){
		//System.out.println("CVTerm:getCVId()");
		return m_CVId.getValue();
	}

	public void setname(String the_name){
		m_name = the_name;
	}

	public String getname(){
		return m_name;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"CVTerm:");
		System.out.println(offsetTxt+"  ID        <"+m_Id+">");
		System.out.println(offsetTxt+"  CVId() KEY<"+m_CVId.getkey()+">");
		System.out.println(offsetTxt+"  CVId()    <"+getCVId()+">");
		System.out.println(offsetTxt+"  name      <"+m_name+">");
	}
}


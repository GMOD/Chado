//Synonym

package org.gmod.chado.chadxtogame;

import java.util.*;

public class Synonym extends Attrib {
private String m_name;
private SMTPTR m_TypeId = new SMTPTR("typeINIT");

	public Synonym(String the_id){
		super(the_id);
	}

	public void setname(String the_name){
		m_name = the_name;
	}

	public String getname(){
		return m_name;
	}

//TYPE_ID
	public void setTypeId(String the_TypeId){
		m_TypeId.setkey(the_TypeId);
	}

	public void setTypeId(Attrib the_gf){
		m_TypeId.setGF(the_gf);
	}

	public void setTypeId(SMTPTR the_SMTPTR){
		m_TypeId = the_SMTPTR;
	}

	public String getTypeId(){
		//System.out.println("SYNONYM:getTypeId()");
		return m_TypeId.getValue();
	}

	public String getTypeIdTxt(){
		System.out.println("SYNONUM:getTypeIdTxt()");
		if(m_TypeId.getObjValue()!=null){
			System.out.println("\tRETURNING<"+((CVTerm)m_TypeId.getObjValue()).getname()+">");
		}else{
			System.out.println("\tRETURNING<NULL>");
		}
		if(m_TypeId.getObjValue()!=null){
			return ((CVTerm)m_TypeId.getObjValue()).getname();
		}
		return null;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"Synonym:");
		System.out.println(offsetTxt+"  name     <"+m_name+">");
	}
}


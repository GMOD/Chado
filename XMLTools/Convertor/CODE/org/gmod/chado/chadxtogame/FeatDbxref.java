//FeatDbxref
package org.gmod.chado.chadxtogame;

import java.util.*;

public class FeatDbxref extends FeatSub {

private String m_iscurrent = null;
private SMTPTR m_DbxrefId = new SMTPTR("dbxref");

	public FeatDbxref(String the_Id){
		super(the_Id);
	}

	public void setiscurrent(String the_iscurrent){
		m_iscurrent = the_iscurrent;
	}

	public String getiscurrent(){
		return m_iscurrent;
	}

	public void setDbxrefId(String the_DbxrefId){
		m_DbxrefId.setkey(the_DbxrefId);
	}

	public void setDbxrefId(Attrib the_gf){
		m_DbxrefId.setGF(the_gf);
	}

	public void setDbxrefId(SMTPTR the_SMTPTR){
		m_DbxrefId = the_SMTPTR;
	}

	public String getDbxrefId(){
		System.out.println("FEATURE:getDbxrefId()");
		return m_DbxrefId.getValue();
	}

	public Dbxref getDbxref(){
		System.out.println("FEATURE:getDbxrefId()");
		return (Dbxref)m_DbxrefId.getObjValue();
	}
}



//FeatProp
package org.gmod.chado.chadxtogame;

import java.util.*;

public class FeatProp extends FeatSub {

private SMTPTR m_PkeyId = new SMTPTR("pkey");
private String m_pval = null;
private String m_prank = null;
private SMTPTR m_PubId = new SMTPTR("pub");

	public FeatProp(String the_id){
		super(the_id);
	}

	public void setPkeyId(String the_PkeyId){
		m_PkeyId.setkey(the_PkeyId);
	}

	public void setPkeyId(Attrib the_gf){
		m_PkeyId.setGF(the_gf);
	}

	public void setPkeyId(SMTPTR the_SMTPTR){
		m_PkeyId = the_SMTPTR;
	}

	public String getPkeyId(){
		//System.out.println("FEATURE:getPkeyId()");
		return m_PkeyId.getValue();
	}

	public void setpval(String the_pval){
		m_pval = the_pval;
	}

	public String getpval(){
		return m_pval;
	}

	public void setprank(String the_prank){
		m_prank = the_prank;
	}

	public String getprank(){
		return m_prank;
	}

	public void setPubId(String the_PubId){
		m_PubId.setkey(the_PubId);
	}

	public void setPubId(Attrib the_gf){
		m_PubId.setGF(the_gf);
	}

	public void setPubId(SMTPTR the_SMTPTR){
		m_PubId = the_SMTPTR;
	}

	public String getPubId(){
		//System.out.println("FEATURE:getPubId()");
		return m_PubId.getValue();
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"FeatProp:");
		System.out.println(offsetTxt+"  PkeyId() <"+getPkeyId()+">");
		String tmp = m_pval;
		if((tmp!=null)&&(tmp.length()>5)){
			tmp = tmp.substring(0,5);
		}
		System.out.println(offsetTxt+"  pval     <"+tmp+">");
		System.out.println(offsetTxt+"  prank    <"+m_prank+">");
		System.out.println(offsetTxt+"  PubId()  <"+getPubId()+">");
	}
}


//Dbxref
package org.gmod.chado.chadxtogame;

import java.util.*;

public class Dbxref extends Attrib {
private String m_dbname;
private String m_accession;

	public Dbxref(String the_id){
		super(the_id);
	}

	public void setdbname(String the_dbname){
		m_dbname = the_dbname;
	}

	public String getdbname(){
		return m_dbname;
	}

	public void setaccession(String the_accession){
		m_accession = the_accession;
	}

	public String getaccession(){
		return m_accession;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"Dbxref:");
		System.out.println(offsetTxt+"  ID        <"+m_Id+">");
		System.out.println(offsetTxt+"  dbname    <"+m_dbname+">");
		System.out.println(offsetTxt+"  accession <"+m_accession+">");
	}
}


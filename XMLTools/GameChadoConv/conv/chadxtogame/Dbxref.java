//Dbxref
package conv.chadxtogame;

import java.util.*;

public class Dbxref extends FeatSub {

private SMTPTR m_DBId = new SMTPTR("db");
//private String m_dbname;
private String m_accession;

	public Dbxref(String the_id){
		super(the_id);
	}

	public void setDBId(String the_DBId){
		m_DBId.setkey(the_DBId);
	}

	public void setDBId(FeatSub the_gf){
		m_DBId.setGF(the_gf);
	}

	public void setDBId(SMTPTR the_SMTPTR){
		m_DBId = the_SMTPTR;
	}

	public String getDBId(){
		//System.out.println("FEATURE:getDBId()");
		return m_DBId.getValue();
	}

	public DB getDB(){
		//System.out.println("FEATURE:getDB()");
		return (DB)m_DBId.getObjValue();
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
		//System.out.println(offsetTxt+"  dbname    <"+m_dbname+">");
		System.out.println(offsetTxt+"  dbname    <"+getDBId()+">");
		System.out.println(offsetTxt+"  accession <"+m_accession+">");
	}
}






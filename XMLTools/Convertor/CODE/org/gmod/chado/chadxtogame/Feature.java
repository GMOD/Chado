//Feature

package org.gmod.chado.chadxtogame;

import java.util.*;

public class Feature extends GenFeat {

private String m_UniqueName;
private String m_timeaccessioned;
private String m_timelastmodified;
private String m_seqlen;
private String m_isanalysis;

//private SMTPTR m_PkeyId = new SMTPTR("pkey");
private SMTPTR m_DbxrefId = new SMTPTR("dbxref");
private Vector m_FeatDbxrefList = new Vector();
private Vector m_FeatSynList = new Vector();

	public Feature(String the_id){
		super(the_id);
	}

	public void setUniqueName(String the_UniqueName){
		m_UniqueName = the_UniqueName;
	}

	public String getUniqueName(){
		return m_UniqueName;
	}

	public void settimeaccessioned(String the_timeaccessioned){
		m_timeaccessioned = the_timeaccessioned;
	}

	public String gettimeaccessioned(){
		return m_timeaccessioned;
	}

	public void settimelastmodified(String the_timelastmodified){
		m_timelastmodified = the_timelastmodified;
	}

	public String gettimelastmodified(){
		return m_timelastmodified;
	}

	public void setseqlen(String the_seqlen){
		m_seqlen = the_seqlen;
	}

	public String getseqlen(){
		return m_seqlen;
	}

	public void setisanalysis(String the_isanalysis){
		m_isanalysis = the_isanalysis;
	}

	public String getisanalysis(){
		return m_isanalysis;
	}

/************************
//PKEY_ID
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
************************/

//DBXREF_ID
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

//FEAT_DBXREF
	public int getFeatDbxrefCount(){
		return m_FeatDbxrefList.size();
	}

	public void addFeatDbxref(FeatDbxref the_gf){
		m_FeatDbxrefList.add(the_gf);
	}

	public FeatDbxref getFeatDbxref(int the_indx){
		System.out.println("FEATURE:getFeatDbxref("+the_indx+")");
		if((the_indx>=0)&&(the_indx<m_FeatDbxrefList.size())){
			return (FeatDbxref)m_FeatDbxrefList.get(the_indx);
		}
		return null;
	}

//FEAT_DBXREF
	public int getFeatSynCount(){
		return m_FeatSynList.size();
	}

	public void addFeatSyn(FeatSub the_gf){
		m_FeatSynList.add(the_gf);
	}

	public FeatSyn getFeatSyn(int the_indx){
		System.out.println("FEATURE:getFeatSyn("+the_indx+")");
		if((the_indx>=0)&&(the_indx<m_FeatSynList.size())){
			return (FeatSyn)m_FeatSynList.get(the_indx);
		}
		return null;
	}
}


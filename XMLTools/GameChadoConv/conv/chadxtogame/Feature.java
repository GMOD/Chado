//Feature

package conv.chadxtogame;

import java.util.*;

public class Feature extends GenFeat {

private String m_timeaccessioned;
private String m_timelastmodified;
private String m_timeexecuted;
private String m_seqlen;
//private String m_isanalysis;
private String m_Residues;
private String m_ResidueType;
private String m_ResidueName;
private String m_Md5;

private SMTPTR m_DbxrefId = new SMTPTR("dbxref");
private SMTPTR m_OrganismId = new SMTPTR("organismINIT");
private SMTPTR m_PubId = new SMTPTR("pubINIT");

private Vector m_FeatDbxrefList = new Vector();
private Vector m_FeatSynList = new Vector();
private Vector m_FeatCVTermList = new Vector();

private Vector m_AttribList = null; //FOR <property>,<gene>,<dbxref>,<comment>
private Vector m_FeatSubList = null; //FOR <property>,<gene>,<dbxref>,<comment>
private Vector m_CompFeatList = null; //FOR <property>,<gene>,<dbxref>,<comment>

//COMP_ANAL
private String m_rawscore = null;
private String m_sourcename = null;
private String m_program = null;
private String m_programversion = null;

	public Feature(String the_id){
		super(the_id);
		m_AttribList = new Vector();
		m_FeatSubList = new Vector();
		m_CompFeatList = new Vector();
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

	public void settimeexecuted(String the_timeexecuted){
		m_timeexecuted = the_timeexecuted;
	}

	public String gettimeexecuted(){
		return m_timeexecuted;
	}

	public void setseqlen(String the_seqlen){
		m_seqlen = the_seqlen;
	}

	public String getseqlen(){
		return m_seqlen;
	}

	//public void setisanalysis(String the_isanalysis){
	//	m_isanalysis = the_isanalysis;
	//}

	//public String getisanalysis(){
	//	return m_isanalysis;
	//}

	public void setResidues(String the_Residues){
//DISABLE
		m_Residues = the_Residues;
//		int lim = 10;
//		if(the_Residues.length()<10){
//			lim = the_Residues.length();
//		}
//		m_Residues = the_Residues.substring(0,lim);
	}

	public String getResidues(){
		return m_Residues;
	}

	public void setResidueType(String the_ResidueType){
		m_ResidueType = the_ResidueType;
	}

	public String getResidueType(){
		return m_ResidueType;
	}

	public void setResidueName(String the_ResidueName){
		m_ResidueName = the_ResidueName;
	}

	public String getResidueName(){
		return m_ResidueName;
	}

	public void setMd5(String the_Md5){
		m_Md5 = the_Md5;
	}

	public String getMd5(){
		return m_Md5;
	}

//DBXREF_ID
	public void setDbxrefId(String the_DbxrefId){
		m_DbxrefId.setkey(the_DbxrefId);
	}

	public void setDbxrefId(FeatSub the_gf){
		m_DbxrefId.setGF(the_gf);
	}

	public void setDbxrefId(SMTPTR the_SMTPTR){
		m_DbxrefId = the_SMTPTR;
	}

	public String getDbxrefId(){
		//System.out.println("FEATURE:getDbxrefId()");
		return m_DbxrefId.getValue();
	}

	public Dbxref getDbxref(){
		//System.out.println("FEATURE:getDbxrefId()");
		return (Dbxref)m_DbxrefId.getObjValue();
	}

//ORGANISM
	public void setOrganismId(String the_OrganismId){
		m_OrganismId.setkey(the_OrganismId);
	}

	public void setOrganismId(FeatSub the_gf){
		m_OrganismId.setGF(the_gf);
	}

	public void setOrganismId(SMTPTR the_SMTPTR){
		m_OrganismId = the_SMTPTR;
	}

	public String getOrganismId(){
		//System.out.println("GENFEAT:getOrganismId()");
		return m_OrganismId.getValue();
	}

//PUB
	public void setPubId(String the_PubId){
		m_PubId.setkey(the_PubId);
	}

	public void setPubId(FeatSub the_gf){
		m_PubId.setGF(the_gf);
	}

	public void setPubId(SMTPTR the_SMTPTR){
		m_PubId = the_SMTPTR;
	}

	public String getPubId(){
		System.out.println("GENFEAT:getPubId()");
		return m_PubId.getValue();
	}


//FEAT_DBXREF
	public int getFeatDbxrefCount(){
		return m_FeatDbxrefList.size();
	}

	public void addFeatDbxref(FeatDbxref the_gf){
//DISABLE
		m_FeatDbxrefList.add(the_gf);
	}

	public FeatDbxref getFeatDbxref(int the_indx){
		//System.out.println("FEATURE:getFeatDbxref("+the_indx+")");
		if((the_indx>=0)&&(the_indx<m_FeatDbxrefList.size())){
			return (FeatDbxref)m_FeatDbxrefList.get(the_indx);
		}
		return null;
	}

//FEAT_SYN
	public int getFeatSynCount(){
		return m_FeatSynList.size();
	}

	public void addFeatSyn(FeatSub the_gf){
		m_FeatSynList.add(the_gf);
	}

	public FeatSyn getFeatSyn(int the_indx){
		//System.out.println("FEATURE:getFeatSyn("+the_indx+")");
		if((the_indx>=0)&&(the_indx<m_FeatSynList.size())){
			return (FeatSyn)m_FeatSynList.get(the_indx);
		}
		return null;
	}

//FEAT_CVTERM
	public int getFeatCVTermCount(){
		return m_FeatCVTermList.size();
	}

	public void addFeatCVTerm(FeatSub the_gf){
		m_FeatCVTermList.add(the_gf);
	}

	public FeatCVTerm getFeatCVTerm(int the_indx){
		//System.out.println("FEATURE:getFeatCVTerm("+the_indx+")");
		if((the_indx>=0)&&(the_indx<m_FeatCVTermList.size())){
			return (FeatCVTerm)m_FeatCVTermList.get(the_indx);
		}
		return null;
	}

//ATTRIB
	public int getAttribCount(){
		if(m_AttribList!=null){
			return m_AttribList.size();
		}else{
			return 0;
		}
	}

	public void addAttrib(FeatSub the_Attrib){
		m_AttribList.add(the_Attrib);
	}

	public FeatSub getAttrib(int the_indx){
		if((the_indx>=0)&&(m_AttribList!=null)
				&&(the_indx<m_AttribList.size())){
			return (FeatSub)m_AttribList.get(the_indx);
		}else{
			return null;
		}
	}

//FEATSUB
	public int getFeatSubCount(){
		if(m_FeatSubList!=null){
			return m_FeatSubList.size();
		}else{
			return 0;
		}
	}

	public void addFeatSub(FeatSub the_FeatSub){
		m_FeatSubList.add(the_FeatSub);
	}

	public FeatSub getFeatSub(int the_indx){
		if((the_indx>=0)&&(m_FeatSubList!=null)
				&&(the_indx<m_FeatSubList.size())){
			return (FeatSub)m_FeatSubList.get(the_indx);
		}else{
			return null;
		}
	}

//COMPFEAT
	public int getCompFeatCount(){
		if(m_CompFeatList!=null){
			return m_CompFeatList.size();
		}else{
			return 0;
		}
	}

	public void addCompFeat(String the_CompFeat){
		m_CompFeatList.add(the_CompFeat);
	}

	public String getCompFeat(int the_indx){
		if((m_CompFeatList!=null)&&(the_indx>=0)
				&&(the_indx<m_CompFeatList.size())){
			return (String)m_CompFeatList.get(the_indx);
		}else{
			return null;
		}
	}

//COMP_ANALYSIS
	public void setrawscore(String the_rawscore){
		m_rawscore = the_rawscore;
	}

	public String getrawscore(){
		return m_rawscore;
	}

	public void setsourcename(String the_sourcename){
		m_sourcename = the_sourcename;
	}

	public String getsourcename(){
		return m_sourcename;
	}

	public void setprogram(String the_program){
		m_program = the_program;
	}

	public String getprogram(){
		return m_program;
	}

	public void setprogramversion(String the_programversion){
		m_programversion = the_programversion;
	}

	public String getprogramversion(){
		return m_programversion;
	}

	public void Display(){
		GenFeat gf = (GenFeat)this;
		for(int i=0;i<gf.getGenFeatCount();i++){
			FeatSub gfs = getGenFeat(i);
			System.out.println("GGG<"+gfs.getTypeId()+">");//+gfs.getId()+">");
			gfs.Display(1);
		}
		for(int i=0;i<getCompFeatCount();i++){
			String s = (String)getCompFeat(i);
			System.out.println("SSS<"+s+">");
		}
	}
}



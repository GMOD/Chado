//GENFEAT

package org.gmod.chado.chadxtogame;

//FOR chado,feature
import java.util.*;

public class GenFeat {
private String m_Id;
private String m_Type;

//APPDATA AND FEATURE
private String m_Name;

//FEATURE
private String m_UniqueName;

//FEATURE
private SMTPTR m_OrganismId = new SMTPTR("organismINIT");
private SMTPTR m_TypeId = new SMTPTR("typeINIT");

//FEATURE_SET AND SEQ
private String m_Residues;

private FeatLoc m_FeatLoc;
private FeatLoc m_AltFeatLoc;

private Vector m_ComponentList = null;
//CHADO AND FEATURE_SET SPECIFIC
private Vector m_AttribList = null; //FOR <property>,<gene>,<dbxref>,<comment>
private Vector m_FeatSubList = null; //FOR <property>,<gene>,<dbxref>,<comment>

//COMPUTATIONAL_ANALYSIS AND ANALYSIS
//private String m_Date;
private String m_Database;
private String m_Program;

//ANALYSIS
private String m_SourceName;
private String m_ProgramVersion;

//ANALYSISFEATURE
private String m_rawscore;

//SEQ SPECIFIC
private String m_ResidueType;
private String m_ResidueName;
private String m_Md5;

//FEATURE_CVTERM AND FEATURE_SYNONYM
private SMTPTR m_PubId = new SMTPTR("pubINIT");


	public GenFeat(String the_Id){
		m_Id = the_Id;

		m_ComponentList = new Vector();
		m_AttribList = new Vector();
		m_FeatSubList = new Vector();
	}

	public void setId(String the_Id){
		m_Id = the_Id;
	}

	public String getId(){
		return m_Id;
	}

	public void setType(String the_Type){
		m_Type = the_Type;
	}

	public String getType(){
		return m_Type;
	}

	public void setName(String the_Name){
		m_Name = the_Name;
	}

	public String getName(){
		return m_Name;
	}

	public void setUniqueName(String the_UniqueName){
		m_UniqueName = the_UniqueName;
	}

	public String getUniqueName(){
		return m_UniqueName;
	}

/****************************/

	public void setFeatLoc(FeatLoc the_FeatLoc){
		m_FeatLoc = the_FeatLoc;
	}

	public FeatLoc getFeatLoc(){
		return m_FeatLoc;
	}

	public void setAltFeatLoc(FeatLoc the_AltFeatLoc){
		m_AltFeatLoc = the_AltFeatLoc;
	}

	public FeatLoc getAltFeatLoc(){
		return m_AltFeatLoc;
	}

	public void setrawscore(String the_rawscore){
		m_rawscore = the_rawscore;
	}

	public String getrawscore(){
		return m_rawscore;
	}

	public void setDatabase(String the_Database){
		m_Database = the_Database;
	}

	public String getDatabase(){
		return m_Database;
	}

	public void setResidues(String the_Residues){
		m_Residues = the_Residues;
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

	public void setProgram(String the_Program){
		m_Program = the_Program;
	}

	public String getProgram(){
		return m_Program;
	}

	//FOR CHADO TO GAME
	public void setSourceName(String the_SourceName){
		m_SourceName = the_SourceName;
	}

	public String getSourceName(){
		return m_SourceName;
	}

	public void setProgramVersion(String the_ProgramVersion){
		m_ProgramVersion = the_ProgramVersion;
	}

	public String getProgramVersion(){
		return m_ProgramVersion;
	}


//ORGANISM
	public void setOrganismId(String the_OrganismId){
		m_OrganismId.setkey(the_OrganismId);
	}

	public void setOrganismId(Attrib the_gf){
		m_OrganismId.setGF(the_gf);
	}

	public void setOrganismId(SMTPTR the_SMTPTR){
		m_OrganismId = the_SMTPTR;
	}

	public String getOrganismId(){
		System.out.println("GENFEAT:getOrganismId()");
		return m_OrganismId.getValue();
	}

//PUB
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
		System.out.println("GENFEAT:getPubId()");
		return m_PubId.getValue();
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
		//System.out.println("GENFEAT:getTypeId()");
		return m_TypeId.getValue();
	}

	public String getTypeIdTxt(){
		/************
		System.out.println("GENFEAT:getTypeIdTxt()");
		if(m_TypeId.getObjValue()!=null){
			System.out.println("\tRETURNING<"+((CVTerm)m_TypeId.getObjValue()).getname()+">");
		}else{
			System.out.println("\tRETURNING<NULL>");
		}
		if(m_TypeId.getObjValue()!=null){
			return ((CVTerm)m_TypeId.getObjValue()).getname();
		}
		return null;
		************/
		return getTypeId();
	}

	public void Display(int the_depth){
		//System.out.println("DISPLAY DEPTH<"+the_depth+">");
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"GENFEAT DISPLAY ID<"+m_Id+"> TYPE<"+getTypeId()+">");
		if(m_rawscore!=null){
			System.out.println(offsetTxt+" SCORE<"+m_rawscore+">");
		}
		if(m_Residues!=null){
			String tmpRes = m_Residues;
			if(tmpRes.length()>10){
				tmpRes = tmpRes.substring(0,10);
			}
			System.out.println(offsetTxt+" Residues<"+tmpRes+">");
		}
		for(int i=0;i<getAttribCount();i++){
			getAttrib(i).Display(the_depth+1);
		}
		for(int i=0;i<getFeatSubCount();i++){
			getFeatSub(i).Display(the_depth+1);
		}
		for(int i=0;i<getGenFeatCount();i++){
			if(getGenFeat(i)!=null){
				getGenFeat(i).Display(the_depth+1);
			}else{
				//System.out.println("+++++++++NULL AT<"+i+">");
			}
		}
	}

	/**********/
	public int getAttribCount(){
		if(m_AttribList!=null){
			return m_AttribList.size();
		}else{
			return 0;
		}
	}

	public void addAttrib(Attrib the_Attrib){
		m_AttribList.add(the_Attrib);
	}

	public Attrib getAttrib(int the_indx){
		if((the_indx>=0)&&(m_AttribList!=null)&&(the_indx<m_AttribList.size())){
			return (Attrib)m_AttribList.get(the_indx);
		}else{
			return null;
		}
	}
	/**********/
	/**********/
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
		if((the_indx>=0)&&(m_FeatSubList!=null)&&(the_indx<m_FeatSubList.size())){
			return (FeatSub)m_FeatSubList.get(the_indx);
		}else{
			return null;
		}
	}
	/**********/

	public int getGenFeatCount(){
		if(m_ComponentList!=null){
			return m_ComponentList.size();
		}else{
			return 0;
		}
	}

	public void addGenFeat(GenFeat the_GenFeat){
		m_ComponentList.add(the_GenFeat);
	}

	public GenFeat getGenFeat(int the_indx){
		if((the_indx>=0)&&(m_ComponentList!=null)&&(the_indx<m_ComponentList.size())){
			return (GenFeat)m_ComponentList.get(the_indx);
		}else{
			return null;
		}
	}
}


//GENFEAT
package org.gmod.chado.gametochadx;

//FOR chado,feature
import java.util.*;

public class GenFeat {
private String m_Id;
private String m_Type;
private boolean m_isChanged = false;
private Span m_Span;
private Vector m_ComponentList = null;
private Vector m_SequenceList = null;

//CHADO SPECIFIC
private String m_Arm;

//CHADO AND FEATURE_SET SPECIFIC
private Vector m_AttribList = null; //FOR <property>,<gene>,<dbxref>,<comment>

//RESULT_SPAN SPECIFIC
private Span m_AltSpan;
private String m_Score;

//COMPUTATIONAL_ANALYSIS SPECIFIC
private String m_Program;
private String m_Database;
private String m_Name;

//FEATURE_SET SPECIFIC (for now)
private String m_Author;
private String m_Residues;
//private String m_ResidueName = null;
private String m_ProducesSeq = null;

//SEQ SPECIFIC
private String m_ResidueType;
private String m_ResidueLength;
private String m_Focus;
private String m_Md5;
private String m_Description;

private String m_date;
private String m_timestamp;

	public GenFeat(String the_Id){
		m_Id = the_Id;
		m_ComponentList = new Vector();
		m_SequenceList = new Vector();
		m_AttribList = new Vector();
	}

	public void setId(String the_Id){
		m_Id = the_Id;
	}

	public String getId(){
		return m_Id;
	}

	public void setSpan(Span the_Span){
		m_Span = the_Span;
	}

	public Span getSpan(){
		return m_Span;
	}

	public void setAltSpan(Span the_AltSpan){
		m_AltSpan = the_AltSpan;
	}

	public Span getAltSpan(){
		return m_AltSpan;
	}

	public void setScore(String the_Score){
		m_Score = the_Score;
	}

	public String getScore(){
		return m_Score;
	}

	public void setDatabase(String the_Database){
		m_Database = the_Database;
	}

	public String getDatabase(){
		return m_Database;
	}

	public void setName(String the_Name){
		//if(m_Name==null){
		//	m_Name="NAME1";
		//}
		m_Name = the_Name;
	}

	public String getName(){
		return m_Name;
	}

	public void setAuthor(String the_Author){
		m_Author = the_Author;
	}

	public String getAuthor(){
		return m_Author;
	}

	public void setResidues(String the_Residues){
		m_Residues = the_Residues;
	}

	public String getResidues(){
		return m_Residues;
	}

/*********
	public void setResidueName(String the_ResidueName){
		m_ResidueName = the_ResidueName;
	}

	public String getResidueName(){
		return m_ResidueName;
	}
*********/

	public void setProducesSeq(String the_ProducesSeq){
		m_ProducesSeq = the_ProducesSeq;
	}

	public String getProducesSeq(){
		return m_ProducesSeq;
	}

	public Vector getProducedSequences(){
		Vector ps = new Vector();
		if((m_ProducesSeq!=null)
				&&(!m_ProducesSeq.equals(""))
				&&(!m_ProducesSeq.equals("null"))){
			ps.add(m_ProducesSeq);
		}
		for(int i=0;i<m_ComponentList.size();i++){
			GenFeat gf = (GenFeat)m_ComponentList.get(i);
			ps.addAll(gf.getProducedSequences());
		}
		return ps;
	}

	public void setResidueType(String the_ResidueType){
		m_ResidueType = the_ResidueType;
	}

	public String getResidueType(){
		return m_ResidueType;
	}

	public void setResidueLength(String the_ResidueLength){
		m_ResidueLength = the_ResidueLength;
	}

	public String getResidueLength(){
		return m_ResidueLength;
	}

	public void setFocus(String the_Focus){
		m_Focus = the_Focus;
	}

	public String getFocus(){
		return m_Focus;
	}

	public void setMd5(String the_Md5){
		m_Md5 = the_Md5;
	}

	public String getMd5(){
		return m_Md5;
	}

	public void setDescription(String the_Description){
		m_Description = the_Description;
	}

	public String getDescription(){
		return m_Description;
	}

	public void setProgram(String the_Program){
		m_Program = the_Program;
	}

	public String getProgram(){
		return m_Program;
	}

	public void setType(String the_Type){
		m_Type = the_Type;
	}

	public String getType(){
		return m_Type;
	}

	public void setChanged(boolean the_isChanged){
		m_isChanged = the_isChanged;
	}

	public boolean isChanged(){
		return m_isChanged;
	}

	public void setArm(String the_Arm){
		m_Arm = the_Arm;
	}

	public String getArm(){
		return m_Arm;
	}

	public void setdate(String the_date){
		m_date = the_date;
	}

	public String getdate(){
		return m_date;
	}

	public void settimestamp(String the_timestamp){
		m_timestamp = the_timestamp;
	}

	public String gettimestamp(){
		return m_timestamp;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"ID<"+m_Id+"> TYPE<"+m_Type+">");
		if(m_Arm!=null){
			System.out.println(offsetTxt+" ARM<"+m_Arm+">");
		}
		if(m_Span!=null){
			System.out.println(offsetTxt+" SPAN<"+m_Span.toString()+">");
		}
		if(m_AltSpan!=null){
			System.out.println(offsetTxt+" ALTSPAN<"+m_AltSpan.toString()+">");
		}
		if(m_Score!=null){
			System.out.println(offsetTxt+" SCORE<"+m_Score+">");
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
		for(int i=0;i<getGenFeatCount();i++){
			getGenFeat(i).Display(the_depth+1);
		}
	}

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
		if((the_indx>=0)&&(m_AttribList!=null)
				&&(the_indx<m_AttribList.size())){
			return (Attrib)m_AttribList.get(the_indx);
		}else{
			return null;
		}
	}

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
		if((the_indx>=0)&&(m_ComponentList!=null)
				&&(the_indx<m_ComponentList.size())){
			return (GenFeat)m_ComponentList.get(the_indx);
		}else{
			return null;
		}
	}

	public void delGenFeat(int the_indx){
		if((the_indx>=0)&&(m_ComponentList!=null)
				&&(the_indx<m_ComponentList.size())){
			m_ComponentList.remove(the_indx);
		}
	}

	public int getSeqCount(){
		if(m_SequenceList!=null){
			return m_SequenceList.size();
		}else{
			return 0;
		}
	}

	public void addSeq(Seq the_Seq){
		m_SequenceList.add(the_Seq);
	}

	public Seq getSeq(int the_indx){
		if((the_indx>=0)&&(m_SequenceList!=null)
				&&(the_indx<m_SequenceList.size())){
			return (Seq)m_SequenceList.get(the_indx);
		}else{
			return null;
		}
	}
}


//GameSaxReader
package conv.gametochadx;

import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.*;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;

import javax.xml.parsers.*;
import java.util.*;
import java.io.*;


public class GameSaxReader extends DefaultHandler {

public static int PARSEGENES = 0;
public static int PARSEALL = 1;
public static int PARSECOMP = 2;
private int m_ParseFlag = 0;

SAXParser parser;
//private String m_CurrTxt = null;

private GenFeat m_CurrFeat;
private Attrib m_CurrAttr;
private Attrib m_CurrPropAttr;
private Attrib m_CurrGeneAttr;
private Attrib m_CurrDbxrefAttr;
private Attrib m_CurrCommentAttr;
private GenFeat m_CurrGame,m_CurrSeq,m_CurrAnnot,m_CurrFeatSet,m_CurrFeatSpan;
private GenFeat m_CurrResultSet,m_CurrResultSpan;
private GenFeat m_CurrCompAnal;
private GDate m_CurrDate;


private Aspect m_CurrAspect;
private SeqRel m_CurrSeqRel;

private String m_SpanStartTxt=null,m_SpanEndTxt=null;
private Span m_Span;

private String m_typeTxt=null,m_xref_dbTxt=null,m_db_xref_idTxt=null;
private String m_valueTxt=null,m_textTxt=null,m_personTxt=null;
private String m_dateTxt=null,m_timestampTxt=null;
private String m_programTxt=null,m_database=null;

private String m_nameTxt=null;

private String m_functionTxt=null;
private String m_processTxt=null;
private String m_componentTxt=null;
private String m_descriptionTxt=null;

private String m_synonymTxt=null;
private String m_organismTxt=null;

private int m_AnnotCount = 0;

private String m_Residues;
private int m_ResiduesLength;
private String m_Alignment;
private int m_align = 0;
private StringBuffer m_SB;

//NEW
private NewModFeat m_nmf;
private boolean m_transBefore = false;
private boolean m_transAfter = false;

//FFFFF
private boolean m_inOutput = false;

	public GameSaxReader(){
		super();
	}

	public void parse(String the_FilePathName,int the_ParseFlag){
		m_ParseFlag = the_ParseFlag;
		try {
			SAXParserFactory sFact = SAXParserFactory.newInstance();
			parser = sFact.newSAXParser();
			InputSource file = new InputSource(the_FilePathName);
			parser.parse(file,this);
		}catch(SAXException e){
			System.out.println("SAXException ");
			e.printStackTrace();
		}catch(ParserConfigurationException e){
			System.out.println("ParserConfigurationException ");
			e.printStackTrace();
		}catch(IOException e){
			System.out.println("IOException ");
			e.printStackTrace();
		}
	}

	public GenFeat getTopNode(){
		return m_CurrGame;
	}

//HAVE startElement THROW A SAXException INDICATING THAT THE RECORD WAS FOUND???
	public void startElement (String namespaceUri, String localName,
		String qualifiedName, Attributes attributes) throws SAXException {
		//System.out.println("MyHandler startElement");
		//System.out.println("NameSpaceURI<"+namespaceUri+">");
		//System.out.println("LocalName<"+localName+">");
		//System.out.println("QualifiedName<"+qualifiedName+">");
		//System.out.println("Attributes<"+attributes.toString()+">");

		m_SB = new StringBuffer();

		//GLOBAL
		if(qualifiedName.equals("game")){
			m_CurrFeat = m_CurrGame = new Game("currentgame");
/****/
//OLD STYLE TRANSACTIONS
		}else if(qualifiedName.equals("deleted_gene")){
			String idTxt = attributes.getValue("id");
			//m_CurrGame.addGenFeat(new ModFeat(idTxt));
			ModFeat mf = new ModFeat(idTxt);
			mf.setType("deleted_gene");
			m_CurrGame.addGenFeat(mf);
			//System.out.println("READ DELETED_GENE <"+idTxt+">");
		}else if(qualifiedName.equals("changed_gene")){
			String idTxt = attributes.getValue("id");
			//m_CurrGame.addGenFeat(new ModFeat(idTxt));
			ModFeat mf = new ModFeat(idTxt);
			mf.setType("changed_gene");
			m_CurrGame.addGenFeat(mf);
			//System.out.println("READ CHANGED_GENE <"+idTxt+">");
		}else if(qualifiedName.equals("deleted_transcript")){
			String idTxt = attributes.getValue("id");
			//m_CurrGame.addGenFeat(new ModFeat(idTxt));
			ModFeat mf = new ModFeat(idTxt);
			mf.setType("deleted_transcript");
			m_CurrGame.addGenFeat(mf);
			//System.out.println("READ DELETED_TRANSCRIPT<"+idTxt+">");
/****/
//NEW STYLE TRANSACTIONS
		}else if(qualifiedName.equals("transaction")){
			//System.out.println("START TRANSACTION");
			m_nmf = new NewModFeat("trans");
		}else if(qualifiedName.equals("before")){
			m_transBefore = true;
		}else if(qualifiedName.equals("after")){
			m_transAfter = true;
/****/
		}else if(qualifiedName.equals("date")){
			String timestampTxt = attributes.getValue("timestamp");
			m_CurrDate = new GDate(timestampTxt);
		//GENE MODEL
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("annotation"))){
			m_AnnotCount++;
			String idTxt = attributes.getValue("id");
			//System.out.println("MAKE Annot NODE<"+idTxt+">");
			m_CurrFeat = m_CurrAnnot = new Annot(idTxt);
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("aspect"))){
			m_CurrFeat = m_CurrAspect = new Aspect();
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("feature_set"))){
			String idTxt = attributes.getValue("id");
			//System.out.println("\tMAKE FeatureSet NODE<"+idTxt+">");
			m_CurrFeat = m_CurrFeatSet = new FeatureSet(idTxt);
			String prodSeqTxt = attributes.getValue("produces_seq");
			if(prodSeqTxt!=null){
				m_CurrFeatSet.setProducesSeq(prodSeqTxt);
			}
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("feature_span"))){
			String idTxt = attributes.getValue("id");
			//System.out.println("\t\tMAKE FeatureSpan NODE<"+idTxt+">");
			m_CurrFeat = m_CurrFeatSpan = new FeatureSpan(idTxt);
			String prodSeqTxt = attributes.getValue("produces_seq");
			if(prodSeqTxt!=null){
				m_CurrFeatSpan.setProducesSeq(prodSeqTxt);
			}
//FSS START
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("seq"))){
			String idTxt = attributes.getValue("id");
			//System.out.println("STARTING SEQ NODE<"+idTxt+">");
			m_CurrSeq = new Seq(idTxt);
			String typeTxt = attributes.getValue("type");
			if(typeTxt!=null){
				m_CurrSeq.setResidueType(typeTxt.trim());
			}
			String lenTxt = attributes.getValue("length");
			if(lenTxt!=null){
				m_CurrSeq.setResidueLength(lenTxt.trim());
			}
			String focusTxt = attributes.getValue("focus");
			if(focusTxt!=null){
				m_CurrSeq.setFocus(focusTxt);
			}
			String md5Txt = attributes.getValue("md5checksum");
			if(md5Txt!=null){
				m_CurrSeq.setMd5(md5Txt);
			}

		}else if(qualifiedName.equals("seq_relationship")){
			String typeTxt = attributes.getValue("type");
			m_CurrSeqRel = new SeqRel("seqrel");
			if(typeTxt!=null){
				m_CurrSeqRel.setSeqType(typeTxt.trim());
			}
			String seqTxt = attributes.getValue("seq");
			if(seqTxt!=null){
				m_CurrSeqRel.setSeqLabel(seqTxt);
			}
			//System.out.println("\t\t\tSTART SEQ_REL TYPE<"+typeTxt
			//		+"> SEQ<"+seqTxt+">");

		}else if(qualifiedName.equals("computational_analysis")){
			String idTxt = attributes.getValue("id");
			//System.out.println("START COMPUTATIONAL_ANALYSIS ID<"+idTxt+">");
			m_CurrFeat = m_CurrCompAnal = new ComputationalAnalysis(idTxt);
		}else if((m_ParseFlag>=1)&&(qualifiedName.equals("result_set"))){
			String idTxt = attributes.getValue("id");
			//System.out.println("\tSTART RESULT_SET ID<"+idTxt+">");
			m_CurrFeat = m_CurrResultSet = new ResultSet(idTxt);
		}else if((m_ParseFlag>=1)&&(qualifiedName.equals("result_span"))){
			String idTxt = attributes.getValue("id");
			//System.out.println("\t\tSTART RESULT_SPAN ID<"+idTxt+">");
			m_CurrFeat = m_CurrResultSpan = new ResultSpan(idTxt);

		//ATTRIBUTES
		}else if(qualifiedName.equals("property")){
			m_CurrAttr = m_CurrPropAttr = new Attrib("property");
			//System.out.println("MADE PROPERTY");
		}else if(qualifiedName.equals("gene")){
			m_CurrAttr = m_CurrGeneAttr = new Attrib("gene");
			//System.out.println("MADE GENE");
		}else if(qualifiedName.equals("dbxref")){
			m_CurrAttr = m_CurrDbxrefAttr = new Attrib("dbxref");
			//System.out.println("MADE DBXREF");
		}else if(qualifiedName.equals("comment")){
			m_CurrAttr = m_CurrCommentAttr = new Attrib("comment");
			//System.out.println("MADE COMMENT");
		}else if(qualifiedName.equals("output")){ //WRAPS 'score'
			m_inOutput = true;
		}
	}

	public void endElement(String namespaceUri,String localName,String qualifiedName){
		//System.out.println("NameSpaceURI<"+namespaceUri+">");
		//System.out.println("LocalName<"+localName+">");
		//System.out.println("LEAVING QualifiedName<"+qualifiedName+">");
		//AFTER ELEMENT CLOSES, GRAB IT'S INNER TEXT
/****/
//NEW STYLE TRANSACTIONS
		if(qualifiedName.equals("transaction")){
			//System.out.println("END TRANSACTION");
			if(m_nmf!=null){
				//System.out.println("ADDING TRANSACTION TO CURRGAME");
				m_CurrGame.addGenFeat(m_nmf);
				m_nmf = null;
			}
		}else if(qualifiedName.equals("before")){
			m_transBefore = false;
		}else if(qualifiedName.equals("after")){
			m_transAfter = false;
/****/
		}else if(qualifiedName.equals("start")){
			m_SpanStartTxt = m_SB.toString();
		}else if(qualifiedName.equals("end")){
			m_SpanEndTxt = m_SB.toString();
		}else if(qualifiedName.equals("seq_relationship")){
			m_Span.setAlignment(m_CurrSeqRel.getAlignment());

			if(m_CurrFeat!=null){
				if(m_CurrFeat.getSpan()==null){
					m_CurrFeat.setSpan(m_Span);
				}else{
					m_CurrFeat.setAltSpan(m_Span);
				}
			}else{
				System.out.println("********No CurrFeat FOR SPAN!");
			}
			m_CurrSeqRel = null;

		}else if(qualifiedName.equals("span")){
			if(m_CurrSeqRel!=null){
				//System.out.println("HAS SRC<"
				//		+m_CurrSeqRel.getSeqLabel()+">");
				m_Span = new Span(m_SpanStartTxt,m_SpanEndTxt,
						m_CurrSeqRel.getSeqLabel());
			}else{
				m_Span = new Span(m_SpanStartTxt,m_SpanEndTxt);
			}
		}else if(qualifiedName.equals("map_position")){
			//System.out.println("********END MAP_POSITION!");
			if(m_CurrGame!=null){
				if(m_Span!=null){
					m_CurrGame.setSpan(m_Span);
				}
			}
		}else if(qualifiedName.equals("score")){
			if(m_CurrFeat!=null){
				m_CurrFeat.setScore(m_SB.toString());
				//System.out.println("SCORE <"+m_CurrFeat.getScore()
				//		+"> PUT IN Feature<"+m_CurrFeat.getId()+">");
			}else{
				System.out.println("********No CurrFeat FOR SCORE!");
			}
		}else if(qualifiedName.equals("program")){
			if(m_CurrFeat!=null){
				m_CurrFeat.setProgram(m_SB.toString());
			}else{
				System.out.println("********No CurrFeat FOR PROGRAM!");
			}
		}else if(qualifiedName.equals("database")){
			if(m_CurrFeat!=null){
				m_CurrFeat.setDatabase(m_SB.toString());
			}else{
				System.out.println("********No CurrFeat FOR DATABASE!");
			}
		}else if(qualifiedName.equals("residues")){
			//System.out.println("\tDONE READING RESIDUES");
			if(m_SB!=null){
				m_Residues = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("alignment")){
			m_Alignment = m_SB.toString().trim();
			//System.out.print("\t\tALIGNMENT["+m_align+"] SAVING LEN<"
			//		+m_Alignment.length()+">");
			m_align++;
			/**/
			String tmp = m_Alignment;
			if((tmp!=null)&&(tmp.length()>10)){
				tmp = tmp.substring(0,9);
			}
			//System.out.println("ALIGN<"+tmp+">");
			/**/

			if(m_CurrSeqRel!=null){
				//System.out.println("\t\t\tIN SEQREL<"+m_CurrSeqRel.getId()+">");
				m_CurrSeqRel.setAlignment(m_Alignment);
			}
			if(m_CurrFeatSpan!=null){
				//System.out.println("\t\t\tIN CURRFEAT_SPAN<"+m_CurrFeatSpan.getId()+">");
			}else{
				//System.out.println("\t\t\tIN CURRFEAT_SPAN IS NULL");
			}
			m_Alignment = null;

		}else if(qualifiedName.equals("type")){
			m_typeTxt = m_SB.toString();
			if((m_CurrAttr!=null)&&(m_CurrAttr.getAttribType().equals("property"))){
				//FOR PROPERTY, NOT FEATURE
				//m_typeTxt = m_SB.toString();
			}else{
				//System.out.println("LOOKING FOR PLACE TO PUT<"+m_typeTxt+"> IN CurrFeat<"+m_CurrFeat.getId()+"> WHICH ALREADY HAS<"+m_CurrFeat.getType()+">");
				if(m_inOutput){
					m_typeTxt = null;
				}else if(m_CurrFeat.getType()==null){
					m_CurrFeat.setType(m_typeTxt);
					//SO IT TAKES ONLY THE FIRST ONE
					//OTHERWISE CONFLICT BETWEEN
					//<result_span><type> AND
					//<result_span><output><type>
//FFFFF
					m_typeTxt = null;
				}
			}
/*****/
		}else if(qualifiedName.equals("author")){
			if(m_SB.toString()!=null){
				if(m_nmf!=null){
	//NEW
					m_nmf.setAuthor(m_SB.toString().trim());
				}else if(m_CurrFeat!=null){
					m_CurrFeat.setAuthor(m_SB.toString().trim());
				}
			}
		}else if(qualifiedName.equals("object_class")){
	//NEW
			if(m_SB.toString()!=null){
				if(m_nmf!=null){
					m_nmf.setObjClass(m_SB.toString().trim());
				}
			}
		}else if(qualifiedName.equals("operation")){
	//NEW
			if(m_SB.toString()!=null){
				if(m_nmf!=null){
					m_nmf.setOperation(m_SB.toString().trim());
				}
			}
		}else if(qualifiedName.equals("annotation_id")){
	//NEW
			if(m_SB.toString()!=null){
				if(m_nmf!=null){
					if(m_transBefore){
						m_nmf.setBeforeAnnotationId(m_SB.toString().trim());
					}else if(m_transAfter){
						m_nmf.setAfterAnnotationId(m_SB.toString().trim());
					}
				}
			}
		}else if(qualifiedName.equals("transcript_name")){
	//NEW
			if(m_SB.toString()!=null){
				if(m_nmf!=null){
					if(m_transBefore){
						m_nmf.setBeforeTranscriptName(m_SB.toString().trim());
					}else if(m_transAfter){
						m_nmf.setAfterTranscriptName(m_SB.toString().trim());
					}
				}
			}
		}else if(qualifiedName.equals("id")){
	//NEW
			if(m_SB.toString()!=null){
				if(m_nmf!=null){
					if(m_transBefore){
						if(m_nmf.getBeforeId1()==null){
							m_nmf.setBeforeId1(m_SB.toString().trim());
						}else{
							m_nmf.setBeforeId2(m_SB.toString().trim());
						}
					}else if(m_transAfter){
						if(m_nmf.getAfterId1()==null){
							m_nmf.setAfterId1(m_SB.toString().trim());
						}else{
							m_nmf.setAfterId2(m_SB.toString().trim());
						}
					}
				}
			}
/*****
	//NEW
		}else if(qualifiedName.equals("name")){
			if(m_SB.toString()!=null){
				if(m_nmf!=null){
					if(m_transBefore){
						m_nmf.setBeforeName(m_SB.toString().trim());
					}else if(m_transAfter){
						m_nmf.setAfterName(m_SB.toString().trim());
					}
				}
			}
****/
		}else if(qualifiedName.equals("date")){
			if(m_SB.toString()!=null){
				m_CurrDate.setdate(m_SB.toString().trim());
				//System.out.println("FOUND DATE STR <"
				//		+m_CurrDate.getdate()+">");
			}
			if(m_CurrDate.getdate()==null){
			}else if(m_nmf!=null){
	//NEW
				m_nmf.setdate(m_CurrDate.getdate());
			}else if(m_CurrAttr!=null){
				//System.out.println(" IN ATTR <"+m_CurrAttr.gettype()+">");
				m_CurrAttr.setdate(m_CurrDate.getdate());
				m_CurrAttr.settimestamp(m_CurrDate.gettimestamp());
			}else if(m_CurrFeat!=null){
				//System.out.println(" IN FEAT <"+m_CurrFeat.getId()+">");
				m_CurrFeat.setdate(m_CurrDate.getdate());
				m_CurrFeat.settimestamp(m_CurrDate.gettimestamp());
				//if((m_CurrAnnot!=null)&&(m_CurrDate.getdate()!=null)){
				//	//PUSH UP TO ANNOTATION ALSO
				//	m_CurrAnnot.setdate(
				//			m_CurrDate.getdate());
				//	m_CurrAnnot.settimestamp(
				//			m_CurrDate.gettimestamp());
				//}
			}else if(m_CurrAnnot!=null){
				//System.out.println(" IN ANNOT <"+m_CurrAnnot.getId()+">");
				//PUSH UP TO ANNOTATION ALSO
				m_CurrAnnot.setdate(m_CurrDate.getdate());
				m_CurrAnnot.settimestamp(m_CurrDate.gettimestamp());
			}
			m_CurrDate = null;
			System.gc();
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("annotation"))){
			//System.out.println("DONE WITH ANNOTATION\n");
			//System.out.println("ADDING Annot TO GAME\n");
			//FIRST, CHECK THIS ANNOTATIONS TRANSCRIPTS
			//AND STEAL ITS DATE
			//for(int i=0;i<m_CurrAnnot.getGenFeatCount();i++){
			//	GenFeat gf = m_CurrAnnot.getGenFeat(i);
			//	System.out.println("STEAL TYPE<"+gf.getType()+">");
			//	System.out.println("\tDATE<"+gf.getdate()+">");
			//}
			if(m_CurrGame!=null){
				m_CurrGame.addGenFeat(m_CurrAnnot);
				m_CurrAnnot = null;
			}else{
				System.out.println("********No CurrGame FOR ANNOT!");
			}
		}else if(qualifiedName.equals("aspect")){
			if(m_functionTxt!=null){
				m_CurrAspect.setFunction(m_functionTxt);
				//System.out.println("ADDING FUNCTION TEXT<"+m_functionTxt+">");
			}
			if(m_processTxt!=null){
				m_CurrAspect.setProcess(m_processTxt);
				//System.out.println("ADDING PROCESS TEXT<"+m_processTxt+">");
			}
			if(m_componentTxt!=null){
				m_CurrAspect.setComponent(m_componentTxt);
				//System.out.println("ADDING COMPONENT TEXT<"+m_componentTxt+">");
			}
			if(m_CurrAnnot!=null){
				m_CurrAnnot.addGenFeat(m_CurrAspect);
				m_CurrAspect = null;
			}else{
				System.out.println("********No CurrAnnot FOR ASPECT!");
			}
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("feature_set"))){
			//System.out.println("\tADDING FEAT_SET<"+m_CurrFeatSet.getId()+"> TO ANNOT");
			if(m_CurrAnnot!=null){
				m_CurrAnnot.addGenFeat(m_CurrFeatSet);
				m_CurrFeatSet = null;
			}else{
				System.out.println("********No CurrAnnot FOR FEATURE_SET!");
			}
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("feature_span"))){
			//System.out.println("\t\tADDING FEAT_SPAN TO FEAT_SET");
			if(m_CurrFeatSet!=null){
				m_CurrFeatSet.addGenFeat(m_CurrFeatSpan);
				m_CurrFeatSpan = null;
			}else{
				System.out.println("********No CurrFeatSet FOR FEATURE_SPAN!");
			}
//FSS END
		}else if((m_ParseFlag<=1)&&(qualifiedName.equals("seq"))){
			//System.out.println("ENDING SEQ NODE<"
			//		+m_CurrSeq.getId()+">");
			if(m_CurrSeq!=null){
				if(m_Residues!=null){
					m_CurrSeq.setResidues(m_Residues);
				}
				if(m_descriptionTxt!=null){
					m_CurrSeq.setDescription(
							m_descriptionTxt);
					m_descriptionTxt=null;
				}
			}
			if(m_CurrFeatSet!=null){ //FEATURE_SET LEVEL
				if(m_CurrSeq!=null){
				if((m_CurrSeq.getResidueType()!=null)
						&&(m_CurrSeq.getResidueType().equals("cdna"))){
					m_CurrSeq.setType("cdna");
				}else if((m_CurrSeq.getResidueType()!=null)
						&&(m_CurrSeq.getResidueType().equals("aa"))){
					m_CurrSeq.setType("aa");
				}
				m_CurrFeatSet.addGenFeat(m_CurrSeq);
				}
			}else{ //GAME LEVEL
				m_CurrGame.addGenFeat(m_CurrSeq);
			}
			m_Residues = null;//CONSUME
			m_CurrSeq = null;//CONSUME

		//COMPUTATIONAL_ANALYSIS
		}else if((m_ParseFlag>=1)&&(qualifiedName.equals("computational_analysis"))){
			System.out.println(" FINISH COMPUTATIONAL_ANALYSIS");
			if(m_CurrGame!=null){
				m_CurrGame.addGenFeat(m_CurrCompAnal);
				m_CurrCompAnal = null;
			}else{
				System.out.println("********No CurrGame FOR COMP_ANAL!");
			}
		}else if((m_ParseFlag>=1)&&(qualifiedName.equals("result_set"))){
			//System.out.print("\t FINISH RESULT_SET WITH NAME<");
			if(m_CurrCompAnal!=null){
				//System.out.println(m_CurrResultSet.getName()+">");
				m_CurrCompAnal.addGenFeat(m_CurrResultSet);
				m_CurrResultSet = null;
			}else{
				System.out.println("********No CurrCompAnal FOR RESULT_SET!");
			}
		}else if((m_ParseFlag>=1)&&(qualifiedName.equals("result_span"))){
			//System.out.print("\t\t FINISH RESULT_SPAN WITH ID<");
			if(m_CurrResultSpan!=null){
				//System.out.println(m_CurrResultSpan.getId()+">");
				m_CurrResultSet.addGenFeat(m_CurrResultSpan);
				m_CurrResultSpan = null;
			}else{
				System.out.println("********No CurrResultSet FOR RESULT_SPAN!");
			}

		}else if(qualifiedName.equals("arm")){
			if(m_CurrGame!=null){
				m_CurrGame.setArm(m_SB.toString());
			}else{
				System.out.println("********No CurrGame!");
			}
		//ATTRIBUTES
		}else if(qualifiedName.equals("property")){
			m_CurrAttr.settype(m_typeTxt);
//FFFFF
			m_typeTxt = null;
			m_CurrAttr.setvalue(m_valueTxt);
			//System.out.println("READ GAME PROPERTY OF TYPE<"
			//		+m_typeTxt
			//		+"> VALUE<"+m_valueTxt+">");
			if((m_typeTxt!=null)&&(m_typeTxt.startsWith("internal"))){
				m_CurrAttr.setisinternal("1");
			}else{
				m_CurrAttr.setisinternal("0");
			}
			if(m_CurrCompAnal!=null){
				m_CurrCompAnal.addAttrib(m_CurrAttr);
			}else if(m_CurrFeat!=null){
				m_CurrFeat.addAttrib(m_CurrAttr);
			}else{
				System.out.println("********No CurrFeat FOR ATTR property!");
			}
			//System.out.println("CONSUME PROPERTY");
			m_CurrAttr = null;
		}else if(qualifiedName.equals("gene")){
			//System.out.println("GENE NAME<"+m_nameTxt+">");
			if(m_nameTxt!=null){
				m_CurrGeneAttr.setname(m_nameTxt);
				m_nameTxt = null;
			}
			if(m_CurrFeat!=null){
				m_CurrFeat.addAttrib(m_CurrAttr);
			}else{
				System.out.println("********No CurrFeat FOR ATTR gene!");
			}
			//System.out.println("CONSUME GENE");
			m_CurrAttr = null;
		}else if(qualifiedName.equals("dbxref")){
			if(m_CurrDbxrefAttr!=null){
				//System.out.println("READ GAME DBXREF DB<"
				//	+m_xref_dbTxt+"> ID<"+m_db_xref_idTxt+">");
				if(m_xref_dbTxt!=null){
					m_CurrDbxrefAttr.setxref_db(m_xref_dbTxt);
				}
				if(m_db_xref_idTxt!=null){
					m_CurrDbxrefAttr.setdb_xref_id(m_db_xref_idTxt);
				}
				if(m_CurrSeq!=null){
					//System.out.println("\tPUT IN SEQ");
					m_CurrSeq.addAttrib(m_CurrDbxrefAttr);
					m_CurrDbxrefAttr = null;
				}else if(m_CurrFeat!=null){
					//System.out.println("\tPUT IN FEAT");
					m_CurrFeat.addAttrib(m_CurrDbxrefAttr);
					m_CurrDbxrefAttr = null;
				}else{
					System.out.println("****No CurrFeat FOR ATTR dbxref!");
				}
				//System.out.println("CONSUME DBXREF");
				m_CurrAttr =null;
			}
		}else if(qualifiedName.equals("comment")){
			m_CurrAttr.settext(m_textTxt);
			if(m_personTxt!=null){
				m_CurrAttr.setperson(m_personTxt);
				m_personTxt = null;
			}
			if(m_CurrDate!=null){
				m_CurrAttr.setdate(m_CurrDate.getdate());
				m_CurrAttr.settimestamp(m_CurrDate.gettimestamp());
				m_CurrDate = null;
			}
			if(m_CurrFeat!=null){
				m_CurrFeat.addAttrib(m_CurrAttr);
			}else{
				System.out.println("********No CurrFeat FOR ATTR comment!");
			}
			//System.out.println("CONSUME COMMENT");
			m_CurrAttr = null;
		//ATTRIBUTE FIELDS
		}else if(qualifiedName.equals("value")){
			if(m_SB.toString()!=null){
				m_valueTxt = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("description")){
			if(m_SB.toString()!=null){
				m_descriptionTxt = m_SB.toString().trim();
			}

		}else if(qualifiedName.equals("name")){
			if(m_SB.toString()!=null){
				m_nameTxt = m_SB.toString().trim();
			}

			if(m_nameTxt!=null){
			if((m_CurrAnnot!=null)
					&&(m_CurrFeatSet==null)
					&&(m_CurrResultSet==null)){
				m_CurrAnnot.setName(m_nameTxt);
			}else if((m_CurrFeatSet!=null)
					&&(m_CurrFeatSpan==null)
					&&(m_CurrSeq==null)){
				m_CurrFeatSet.setName(m_nameTxt);
			}else if((m_CurrFeatSpan!=null)
					&&(m_CurrSeq==null)){
				m_CurrFeatSpan.setName(m_nameTxt);
			}else if((m_CurrResultSet!=null)
					&&(m_CurrResultSpan==null)
					&&(m_CurrSeq==null)){
				m_CurrResultSet.setName(m_nameTxt);
			}else if((m_CurrResultSpan!=null)
					&&(m_CurrSeq==null)){
				m_CurrResultSpan.setName(m_nameTxt);
			}else if(m_CurrSeq!=null){
				m_CurrSeq.setName(m_nameTxt);
			}else if(m_nmf!=null){
/****/
//NEW
				//System.out.println("NMF NAME");
				if(m_transBefore){
					m_nmf.setBeforeName(m_SB.toString().trim());
				}else if(m_transAfter){
					m_nmf.setAfterName(m_SB.toString().trim());
				}
/****/
			}else{
				//System.out.println("NAME<"+m_nameTxt
				//		+">TYPE<"+m_CurrFeat.getType()
				//		+"> OF OTHER<"
				//		+m_CurrFeat.getId()+">");
			}
			m_nameTxt = null;
			}

		}else if(qualifiedName.equals("xref_db")){
			if(m_SB.toString()!=null){
				m_xref_dbTxt = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("db_xref_id")){
			if(m_SB.toString()!=null){
				m_db_xref_idTxt = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("text")){
			if(m_SB.toString()!=null){
				m_textTxt = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("person")){
			if(m_SB.toString()!=null){
				m_personTxt = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("date")){
			if(m_SB.toString()!=null){
				m_dateTxt = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("function")){
			if(m_SB.toString()!=null){
				m_functionTxt = m_SB.toString().trim();
			}
		//GUESSING AT THE NEXT TWO, HAVE NOT SEEN EXAMPLES
		}else if(qualifiedName.equals("process")){
			if(m_SB.toString()!=null){
				m_processTxt = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("component")){
			if(m_SB.toString()!=null){
				m_componentTxt = m_SB.toString().trim();
			}
		}else if((qualifiedName.equals("synonym"))
				||(qualifiedName.equals("internal_synonym"))){
			//System.out.println("READ SYN OF TYPE<"
			//		+qualifiedName+">");
			if(m_SB.toString()!=null){
				m_synonymTxt = m_SB.toString().trim();
				//System.out.println("READ SYNONYM<"
				//		+m_synonymTxt+">");
				Attrib tmp = new Attrib("property");
				tmp.settype("internal_synonym");
				tmp.setvalue(m_synonymTxt);
				if(qualifiedName.startsWith("internal")){
					tmp.setisinternal("1");
				}else{
					tmp.setisinternal("0");
				}
				m_CurrFeat.addAttrib(tmp);
			}
		}else if(qualifiedName.equals("organism")){
			if(m_SB.toString()!=null){
				m_organismTxt = m_SB.toString().trim();
			}
		//UNUSED
		}else if(qualifiedName.equals("computational_analysis")){
		}else if(qualifiedName.equals("result_set")){
		}else if(qualifiedName.equals("result_span")){
		}else if(qualifiedName.equals("game")){
		}else if(qualifiedName.equals("output")){ //WRAPS 'score'
			m_inOutput = false;
//FFFFF
			m_typeTxt = null;
			//SINCE 'output' ISNT USED, NEITHER SHOULD ITS TYPE
		}else if(qualifiedName.equals("deleted_gene")){
		}else if(qualifiedName.equals("deleted_transcript")){
		}else if(qualifiedName.equals("changed_gene")){
		}else if(qualifiedName.equals("evidence")){
		}else if(qualifiedName.equals("internal")){
		}else{
			System.out.println("----UNUSED GAME ELEMENT<"
					+qualifiedName+">");
		}
	}

	public void characters(char[] ch,int start,int length){
		m_SB.append(new String(ch,start,length));
		//System.out.println("\t\tCHARACTERS LEN<"+ch.length+">");
	}


	public Span calcCDSSpan(String the_DeclResidueLength,
			GenFeat the_CurrFeatSet){
		System.out.println("CALC CDS SPAN");
		Vector SpanList = new Vector();
		Span TSSSpan = null;
		int protlen = 0;
		try{
			if((the_DeclResidueLength!=null)
					&&(the_DeclResidueLength.length()>0)){
				String numStr = the_DeclResidueLength.replace('"',' ').trim();
				protlen = (Integer.decode(numStr)).intValue();
			}
		}catch(Exception ex){
		}
		int bplen = (protlen*3);
		for(int i=0;i<the_CurrFeatSet.getGenFeatCount();i++){
			GenFeat gf = the_CurrFeatSet.getGenFeat(i);
			if((gf.getType()==null)
				||(gf.getType().startsWith("translate"))
				||(gf.getType().startsWith("start_codon"))){
				TSSSpan = gf.getSpan();
			}else if(gf.getType().startsWith("exon")){
				SpanList.add(gf.getSpan());
			}
		}
		if(TSSSpan!=null){
			int startpos = TSSSpan.getStart();
			int endpos = getEndpoint(SpanList,startpos,bplen);
			System.out.println("CALC CDS SPAN<"+startpos+".."
					+endpos+">");
			return new Span(startpos,endpos);
		}else{
			System.out.println("CALC CDS SPAN<null>");
			return null;
		}
	}

	private int getEndpoint(Vector the_SpanList,int the_start,int the_len){
		int endPos = 0;
		int i=0;
		while(i<the_SpanList.size()){
			Span sp = (Span)the_SpanList.get(i);
			if(sp.getStart()<sp.getEnd()){
				if(the_start>=sp.getStart()){
					if(the_start<=sp.getEnd()){
						int deduction = Math.abs(-sp.getEnd()+the_start-1);
						the_len -= deduction;
						i++;
						break;
					}
				}
				i++;
			}else{
				if(the_start<=sp.getStart()){
					if(the_start>=sp.getEnd()){
						int deduction = Math.abs(-the_start+sp.getEnd()+1);
						the_len -= deduction;
						i++;
						break;
					}
				}
				i++;
			}
		}

		while(i<the_SpanList.size()){
			Span sp = (Span)the_SpanList.get(i);
			int SegLen = sp.getLength();
			if(the_len>SegLen){
				the_len -= SegLen;
			}else{
				if(sp.getStart()<sp.getEnd()){
					//PEILI FIX
					//endPos = (sp.getStart()+the_len-1);
					endPos = (sp.getStart()+the_len);
				}else{
					endPos = (sp.getStart()-the_len+1);
				}
				break;
			}
			i++;
		}
		return endPos;
        }

	public static void main(String args[]){
		GameSaxReader pd = new GameSaxReader();
		//String fn = "/users/smutniak/Chado1/Samples/CG10077.smallsample.xml";
		//String fn = "/users/smutniak/Chado1/Samples/CG10077.crosby.complete.xml";
		//String fn = "/users/smutniak/Chado1/ChngDel/AE003650.changed.xml";
		//21MB
		//String fn = "/users/stan/xml/apollo/AE003462.Feb.Oct11.xml";
		//10MB
		//String fn = "/users/stan/xml/apollo/AE003418.Jun.Oct11.xml";
		String fn = "../OUT/CG10077.crosby.complete.xml";
		//String fn = "../OUT/CG10077.small.xml";
		pd.parse(fn,GameSaxReader.PARSEALL);
		GenFeat topnode = pd.getTopNode();
		//topnode.Display(0);
	}
}


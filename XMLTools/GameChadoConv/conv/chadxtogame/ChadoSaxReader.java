//ChadoSaxReader.java

package conv.chadxtogame;

import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.*;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;

//import com.sun.xml.tree.*;
//import com.sun.xml.parser.Parser.*;

import javax.xml.parsers.*;
import java.util.*;
import java.io.*;


public class ChadoSaxReader extends DefaultHandler {
SAXParser parser;

private Stack m_Stack = new Stack();
private Stack m_CurrTypeStack = new Stack();

private StringBuffer m_SB = null;

private Feature m_CurrGenFeat;
private Feature m_CurrChado;
private Feature m_CurrFeature;
private Appdata m_CurrAppdata;

private String m_nameTxt = null;

private SMTPTR m_CurrCVId;
private CV m_CurrCV;

private SMTPTR m_CurrDBId;
private DB m_CurrDB;

private SMTPTR m_CurrDbxrefId;
private Dbxref m_CurrDbxref;

private SMTPTR m_CurrOrganismId;
private Organism m_CurrOrganism;

private SMTPTR m_CurrPubId;
private Pub m_CurrPub;

private SMTPTR m_CurrTypeId;
private SMTPTR m_CurrCVTermId;
private CVTerm m_CurrCVTerm;

private FeatLoc m_CurrFeatLoc;
private String m_SpanStartTxt=null,m_SpanEndTxt=null;

private FeatProp m_CurrFeatProp;


//FEATURE_DBXREF
private FeatDbxref m_CurrFeatDbxref;
private Synonym m_CurrSynonym;
private FeatRel m_CurrFeatRel;
private FeatSub m_CurrFEATSUB;
private FeatSyn m_CurrFeatSyn;
private FeatAnal m_CurrFeatAnal;
private FeatCVTerm m_CurrFeatCVTerm;

private FeatSub m_CurrFeatEvid;//,m_CurrFeatCVTerm;
//private FeatEvid m_CurrFeatEvid;

//FEATURELOC
//FEATUREPROP

private CompAnal m_CurrCompAnal;

private String m_CurrSrcFeatureIdTxt=null;
private SMTPTR m_CurrFEATID;
private SMTPTR m_CurrSrcFeatureId,m_CurrSubjectId,m_CurrObjectId;
private SMTPTR m_CurrEvidenceId,m_CurrAnalysisId,m_CurrSynonymId;

private String m_iscurrentTxt = null;

//private boolean m_GeneOnly = true;
private int m_readMode = GameWriter.CONVERT_ALL;
private boolean m_inAnalysis = false;
private boolean m_isUseful = true;

private String m_CurrFeatLocName = null;
private int m_depth = 0;

private String m_CVTERMname = null;

	public ChadoSaxReader(){
		super();
	}

	public int parse(String the_FilePathName,
			//boolean the_GeneOnly){
			int the_readMode){
		//m_GeneOnly = the_GeneOnly;
		m_readMode = the_readMode;
		try {
			SAXParserFactory sFact = SAXParserFactory.newInstance();
			parser = sFact.newSAXParser();
			InputSource file = new InputSource(the_FilePathName);
			if(file!=null){
				parser.parse(file,this);
			}else{
				System.out.println("File <"+the_FilePathName+"> NOT FOUND!");
				return -1;
			}
			
		}catch(SAXException e){
			System.out.println("SAXException ");
			//e.printStackTrace();
			return -2;
		}catch(ParserConfigurationException e){
			System.out.println("ParserConfigurationException ");
			//e.printStackTrace();
			return -3;
		}catch(IOException e){
			System.out.println("IOException ");
			//e.printStackTrace();
			return -4;
		}
		return 0;
	}

	public GenFeat getTopNode(){
		return m_CurrChado;
	}


	public void startElement (String namespaceUri, String localName,
			String qualifiedName, Attributes attributes)
			throws SAXException {
		//System.out.println("MyHandler startElement");
		//System.out.println("NameSpaceURI<"+namespaceUri+">");
		//System.out.println("LocalName<"+localName+">");

		//for(int i=0;i<m_depth;i++){
		//	System.out.print(" ");
		//}
		//m_depth++;
		//System.out.println("START QualifiedName<"+qualifiedName+">");

		//System.out.println("Attributes<"+attributes.toString()+">");
		m_SB = new StringBuffer();

		if(qualifiedName.equals("chado")){
			m_CurrGenFeat = m_CurrChado = new Feature("currentchado");
			m_Stack.push(m_CurrChado);//BOTTOM OF THE STACK
			
		}else if(qualifiedName.equals("_appdata")){
			String idTxt = attributes.getValue("name");
			m_CurrAppdata = new Appdata(idTxt);

		}else if(qualifiedName.equals("feature")){
			String idTxt = attributes.getValue("id");
			//System.out.println("START FEATURE ID<"+idTxt+">");
			//String m_OFFSET = "";
			//for(int i=0;i<m_Stack.size();i++){
			//	m_OFFSET += "\t";
			//}
			//System.out.println(m_OFFSET+"STARTING FEATURE ID<"+idTxt+">");
			if(idTxt==null){
				idTxt = attributes.getValue("ref");
			}
			m_CurrGenFeat = m_CurrFeature = new Feature(idTxt);
			m_Stack.push(m_CurrFeature);
			m_CurrTypeStack.push(m_CurrFeature);
			if(m_CurrSrcFeatureId!=null){
				m_CurrSrcFeatureIdTxt = m_CurrFeature.getId();
			}

		}else if(qualifiedName.equals("feature_relationship")){
			String idTxt = attributes.getValue("id");
			m_CurrFeatRel = new FeatRel(idTxt);
			m_CurrTypeStack.push(m_CurrFeatRel);

		}else if(qualifiedName.equals("feature_dbxref")){
			String idTxt = attributes.getValue("id");
			m_CurrFeatDbxref = new FeatDbxref(idTxt);
			//System.out.println("\tSTART feature_dbxref ID<"+idTxt+">");

		}else if(qualifiedName.equals("feature_synonym")){
			String idTxt = attributes.getValue("id");
			m_CurrFEATSUB = m_CurrFeatSyn = new FeatSyn(idTxt);

		}else if(qualifiedName.equals("feature_cvterm")){
			String idTxt = attributes.getValue("id");
			m_CurrFEATSUB = m_CurrFeatCVTerm = new FeatCVTerm(idTxt);

		}else if(qualifiedName.equals("analysis")){
			m_CurrFeatAnal = new FeatAnal("analysis");
			m_Stack.push(m_CurrFeature);

		}else if(qualifiedName.equals("synonym")){
			String idTxt = attributes.getValue("id");
			m_CurrSynonym = new Synonym(idTxt);
			m_CurrTypeStack.push(m_CurrSynonym);

		}else if(qualifiedName.equals("featureloc")){
			//System.out.println("CSR: HELLO FEATURELOC");
			String idTxt = attributes.getValue("id");
			m_CurrFeatLoc = new FeatLoc(idTxt);
			m_CurrTypeStack.push(m_CurrFeatLoc);

		}else if(qualifiedName.equals("featureprop")){
			String idTxt = attributes.getValue("id");
			m_CurrFeatProp = new FeatProp(idTxt);
			m_CurrTypeStack.push(m_CurrFeatProp);

		}else if(qualifiedName.equals("featureprop_pub")){
			//DO NOTHING

		}else if(qualifiedName.equals("srcfeature_id")){
			//System.out.println("\tCSR: HELLO SRCFEATURE_ID");
			m_CurrFEATID = m_CurrSrcFeatureId = new SMTPTR("feature");

		}else if(qualifiedName.equals("subject_id")){
			m_CurrFEATID = m_CurrSubjectId = new SMTPTR("feature");
			//FEATURE_RELATIONSHIP
		}else if(qualifiedName.equals("object_id")){
			m_CurrFEATID = m_CurrObjectId = new SMTPTR("feature");
			//FEATURE_RELATIONSHIP
		}else if(qualifiedName.equals("evidence_id")){
			m_CurrFEATID = m_CurrEvidenceId = new SMTPTR("evidence");
			//FEATURE_EVIDENCE
		}else if(qualifiedName.equals("analysis_id")){
			m_CurrFEATID = m_CurrAnalysisId = new SMTPTR("analysis");
			//ANALYSISFEATURE
		}else if(qualifiedName.equals("synonym_id")){
			m_CurrFEATID = m_CurrSynonymId = new SMTPTR("synonym");
			//FEATURE_SYNONYM

//START CVTERM,TYPE_ID,PKEY_ID
		}else if(qualifiedName.equals("cvterm_id")){
			m_CurrCVTermId = new SMTPTR("cvterm");
		}else if(qualifiedName.equals("type_id")){
			m_CurrTypeId = new SMTPTR("type");
		}else if(qualifiedName.equals("cvterm")){
			String idTxt = attributes.getValue("id");
			m_CurrCVTerm = new CVTerm(idTxt);
//END CVTERM,TYPE_ID,PKEY_ID

//CV
		}else if(qualifiedName.equals("cv_id")){
			m_CurrCVId = new SMTPTR("cv");

		}else if(qualifiedName.equals("cv")){
			String idTxt = attributes.getValue("id");
			m_CurrCV = new CV(idTxt);

//DB
		}else if(qualifiedName.equals("db_id")){
			m_CurrDBId = new SMTPTR("db");
		}else if(qualifiedName.equals("db")){
			String idTxt = attributes.getValue("id");
			m_CurrDB = new DB(idTxt);

//DBXREF
		}else if(qualifiedName.equals("dbxref_id")){
			m_CurrDbxrefId = new SMTPTR("dbxref");
			//System.out.println("\t\tSTART dbxref_id");
		}else if(qualifiedName.equals("dbxref")){
			String idTxt = attributes.getValue("id");
			m_CurrDbxref = new Dbxref(idTxt);
			//System.out.println("\t\t\tSTART dbxref ID<"
			//		+idTxt+">");

//ORGANISM
		}else if(qualifiedName.equals("organism_id")){
			m_CurrOrganismId = new SMTPTR("organism");
		}else if(qualifiedName.equals("organism")){
			String idTxt = attributes.getValue("id");
			m_CurrOrganism = new Organism(idTxt);

//PUB
		}else if(qualifiedName.equals("pub_id")){
			m_CurrPubId = new SMTPTR("pub");
		}else if(qualifiedName.equals("pub")){
			String idTxt = attributes.getValue("id");
			//System.out.println("=MAKE PUB <"+idTxt+">");
			m_CurrPub = new Pub(idTxt);
			m_CurrTypeStack.push(m_CurrPub);
		}
	}

	public void endElement(String namespaceUri,String localName,
				String qualifiedName){
		//m_depth--;
		//for(int i=0;i<m_depth;i++){
		//	System.out.print(" ");
		//}
		//System.out.println("END QualifiedName<"+qualifiedName+">");

		if(qualifiedName.equals("chado")){
			m_CurrChado.Display(0);
			//DO NOTHING

		}else if(qualifiedName.equals("_appdata")){
			if(m_SB.toString()!=null){
				m_CurrAppdata.setText(m_SB.toString().trim());
			}
			m_CurrChado.addGenFeat(m_CurrAppdata);

		}else if(qualifiedName.equals("feature")){ //END
			GenFeat endingFeature = (GenFeat)m_Stack.pop();
			//System.out.println("END FEATURE NAME<"
			//		+endingFeature.getName()+">");
			GenFeat surroundingFeature = (GenFeat)m_Stack.peek();

			//STACK STUFF
			if(m_isUseful){
				surroundingFeature.addGenFeat(endingFeature);
			}
			if(surroundingFeature instanceof Feature){
				if((m_readMode==GameWriter.CONVERT_GENE)&&(m_inAnalysis)){
					//System.out.println("===========IS ANALYSIS, NOT SAVED");
				}else{
					//System.out.println("===========IS GENE, IS SAVED");
					if(m_isUseful){
						Mapping.Add(endingFeature.getId(),endingFeature);
						//System.out.println(" SAVING");
					}else{
						//System.out.println(" NOT SAVING");
					}
					if(m_CurrFEATID!=null){
						m_CurrFEATID.setkey(endingFeature.getId());
					}
					m_CurrFeature = (Feature)surroundingFeature;
				}
				m_CurrTypeStack.pop();
			}else if(surroundingFeature instanceof Chado){
				//if((m_readMode==GameWriter.CONVERT_GENE)&&(endingFeature.isMatch())){
				if(endingFeature.isMatch()){
					m_inAnalysis = true;
				}else{
					if(m_isUseful){
						Mapping.Add(endingFeature.getId(),endingFeature);
						//System.out.println(" SAVING");
					}else{
						//System.out.println(" NOT SAVING");
					}
					m_inAnalysis = false;
				}
			}else{
				System.out.println("RETURNING TO UNKNOWN");
			}


			//SMTPTR
			if(m_isUseful){
				if(m_CurrSubjectId!=null){
					m_CurrFeature.addCompFeat(endingFeature.getId());
				}
				m_CurrFeatLocName = endingFeature.getName();
				//System.out.println("\tCSR: FEATLOCNAME SET TO <"
				//		+m_CurrFeatLocName+">");
				//System.out.println(" SAVING");
			}else{
				//System.out.println(" NOT SAVING");
			}
			//String m_OFFSET = "";
			//for(int i=0;i<m_Stack.size();i++){
			//	m_OFFSET += "\t";
			//}
			//System.out.println(m_OFFSET+"ENDING FEATURE ID<"+endingFeature.getId()
			//		+"> DEPTH<"+m_Stack.size()
			//		+"> IS_ANALYSIS<"+endingFeature.getisanalysis()
			//		+">");

		}else if(qualifiedName.equals("analysis")){
			GenFeat endingFeature = (GenFeat)m_Stack.pop();
			GenFeat surroundingFeature = (GenFeat)m_Stack.peek();

			if(m_isUseful){
				surroundingFeature.addGenFeat(endingFeature);
			}

			if(surroundingFeature instanceof Feature){
				m_CurrFeature = (Feature)surroundingFeature;
			}
			if(m_CurrFeatAnal!=null){
				m_CurrFeature.setsourcename(
						m_CurrFeatAnal.getsourcename());
				m_CurrFeature.setprogram(
						m_CurrFeatAnal.getprogram());
				m_CurrFeature.setprogramversion(
						m_CurrFeatAnal.getprogramversion());
				m_CurrFeatAnal = null;
			}

		}else if(qualifiedName.equals("synonym")){
			//System.out.println("  FINISH SYNONYM");
			m_CurrSynonym = (Synonym)m_CurrTypeStack.pop();
			//SYNONYM_ID
			if(m_CurrSynonymId!=null){
				//System.out.println("PUTTING SYNONYM (name)<"
				//		+m_CurrSynonym.getname()
				//		+">  IN SYNONYMID");
				m_CurrSynonymId.setGF(m_CurrSynonym);
				m_CurrSynonym = null;//CONSUME
			}

		}else if(qualifiedName.equals("feature_relationship")){
			m_CurrFeatRel = (FeatRel)m_CurrTypeStack.pop();
			//FEATURE

		}else if(qualifiedName.equals("featureloc")){
			//System.out.println("CSR: GOODBYE FEATLOC SET SPAN.SRC TO<"
			//		+m_CurrFeatLocName+">");
			Span tmpSpan = new Span(m_SpanStartTxt,m_SpanEndTxt,m_CurrFeatLocName);
			m_CurrFeatLoc = (FeatLoc)m_CurrTypeStack.pop();
			//BUILD
			if(m_CurrFeatLoc.getSpan()==null){
				m_CurrFeatLoc.setSpan(tmpSpan);
			}
			if(m_CurrFeatLoc.getAlign()==null){
				m_CurrFeatLoc.setAlign(
						m_CurrFeature.getResidues());
			}
			if(m_CurrSrcFeatureIdTxt!=null){
				m_CurrFeatLoc.setSrcFeatureId(
						m_CurrSrcFeatureIdTxt);
			}else{
				//System.out.println("\t\tCSR: FEATLOC SRC FEATURE ID <NULL> FOR SPAN<"
				//		+tmpSpan.toString()+">");
			}
			//LOCATE
			if(m_CurrFeature!=null){
				//System.out.println("\t\tCSR: FEATLOC  PUT INTO FEATURE UN<"
				//		+m_CurrFeature.getUniqueName()+">");
				//System.out.println("AT THIS PT, FEATLOCNAME IS<"
				//		+m_CurrFeatLocName+">");
				if(m_CurrFeature.getFeatLoc()==null){
					m_CurrFeature.setFeatLoc(m_CurrFeatLoc);
				}else{
					m_CurrFeature.setAltFeatLoc(m_CurrFeatLoc);
				}
				m_CurrFeatLoc = null;
			}

		}else if(qualifiedName.equals("featureprop")){
			//System.out.println("ENDING FEATURPROP");
			m_CurrFeatProp = (FeatProp)m_CurrTypeStack.pop();

			if(m_CurrPubId!=null){
				//System.out.println("SETTING_FEATUREPROP_TO_PUBID<"
				//		+m_CurrPubId+">");
				m_CurrFeatProp.setPubId(m_CurrPubId);
				m_CurrPubId = null;//CONSUME
			}
			//LOCATE
			if(m_CurrFeature!=null){
				m_CurrFeature.addFeatSub(m_CurrFeatProp);
				m_CurrFeatProp = null;
			}

		}else if(qualifiedName.equals("featureprop_pub")){
			//HOLDS A PUB_ID FOR FEATUREPROP
		}else if(qualifiedName.equals("feature_dbxref")){
			//BUILD
			if(m_iscurrentTxt!=null){
				m_CurrFeatDbxref.setiscurrent(
						m_iscurrentTxt);
				m_iscurrentTxt = null;
			}
			//LOCATE
			if(m_CurrFeature!=null){
				//System.out.println("\t****PUT feature_dbxref INTO feature ID<"+m_CurrFeature.getId()+"> NAME<"+m_CurrFeature.getName()+">");
				m_CurrFeature.addFeatDbxref(m_CurrFeatDbxref);
				m_CurrFeatDbxref = null;//CONSUME
			}
			//System.out.println("\tEND feature_dbxref\n");

		}else if(qualifiedName.equals("feature_synonym")){
			//System.out.println("FINISH FEATURE_SYNONYM");
			//BUILD
			if(m_iscurrentTxt!=null){
				m_CurrFeatSyn.setiscurrent(
						m_iscurrentTxt);
				m_iscurrentTxt = null;
			}
			
			//LOCATE
			if(m_CurrFeature!=null){
				m_CurrFeature.addFeatSyn(m_CurrFeatSyn);
				m_CurrFeatSyn = null;//CONSUME
			}
		}else if(qualifiedName.equals("feature_evidence")){
			//LOCATE
			//if(m_CurrFeature!=null){
			//	m_CurrFeature.addFeatEvid(m_CurrFeatEvid);
			//	m_CurrFeatEvid = null;//CONSUME
			//}
			m_CurrFeatEvid = null;//CONSUME
		}else if(qualifiedName.equals("feature_cvterm")){
			//LOCATE
			if(m_CurrFeature!=null){
				m_CurrFeature.addFeatCVTerm(m_CurrFeatCVTerm);
				m_CurrFeatCVTerm = null;//CONSUME
			}
			m_CurrFeatCVTerm = null;//CONSUME


		//}else if(qualifiedName.equals("feature_id")){
		//	//m_CurrFEATID = null;
		//	//FEATURELOC
		}else if(qualifiedName.equals("srcfeature_id")){ //END
//KLUDGE
			//BUILD
			if(m_CurrSrcFeatureIdTxt==null){
				m_CurrSrcFeatureIdTxt = m_SB.toString().trim();
			}
			if(m_CurrFeatLoc!=null){
				m_CurrFeatLoc.setSrcFeatureId(
						m_CurrSrcFeatureIdTxt);
				m_CurrSrcFeatureIdTxt = null;
			}
			m_CurrSrcFeatureId = null;
			//FEATURELOC
			//System.out.println("\tCSR: GOODBYE SRCFEATURE_ID WITH FEATLOCNAME<"
			//		+m_CurrFeatLocName+">");
		}else if(qualifiedName.equals("subject_id")){
			m_CurrSubjectId = null;
		}else if(qualifiedName.equals("object_id")){
			//m_CurrFEATID = null;
			//FEATURE_RELATIONSHIP

		}else if(qualifiedName.equals("evidence_id")){
			//m_CurrFEATID = null;
			//FEATURE_EVIDENCE
		}else if(qualifiedName.equals("analysis_id")){
			//m_CurrFEATID = null;
			//ANALYSISFEATURE
		}else if(qualifiedName.equals("synonym_id")){
			//System.out.println(" FINISH SYNONYM_ID");
			//m_CurrFEATID = null;
			//FEATURE_SYNONYM
			//BUILD
			//System.out.println("GONNA PUT SYNONYM_ID IN FEATURE_SYNONYM");
			if(m_CurrSynonymId.getGF()==null){
				//System.out.println("1 NOT NULL");
				m_CurrSynonymId.setkey(m_SB.toString().trim());
			}else{
				//System.out.println("1 IS NULL");
			}
			//LOCATE
			if(m_CurrFeatSyn!=null){
				//System.out.println("2 NOT NULL");
				m_CurrFeatSyn.setSynonymId(m_CurrSynonymId);
				m_CurrSynonymId = null;//CONSUME
			}else{
				//System.out.println("2 IS NULL");
			}

//START CVTERM,TYPE_ID,PKEY_ID
		}else if(qualifiedName.equals("cvterm")){
			//BUILD
			if(m_nameTxt!=null){
				m_CurrCVTerm.setname(m_nameTxt);
			}
			//System.out.println("++FSS CVTERM NAME<"
			//		+m_CurrCVTerm.getname()+">");
			//System.out.println("CVTERM_NAME<"+m_CVTERMname
			//		+"> FOR<"+m_CurrCVTerm.getname()+">");
			if((m_CurrCVTerm!=null)&&(m_CurrCVTerm.getname()!=null)
					&&(m_CVTERMname!=null)
					&&(m_CurrCVTerm.getname().equals("evidence"))
					&&(m_CVTERMname.equals("GenBank feature qualifier"))){
				//FIX FOR PROBLEM OF GB QUALIFIER ALSO USING TYPE 'evidence'
				m_CurrCVTerm.setname("evidenceGB");
			}
			//LOCATE
			if(m_CurrTypeId!=null){
				m_CurrTypeId.setGF(m_CurrCVTerm);
				m_CurrCVTerm = null;//CONSUME
				//System.out.println("++FSS CVTERM TYPE<"
				//		+((CVTerm)(m_CurrTypeId.getGF())).getname()+">");
			}else if(m_CurrCVTermId!=null){
				m_CurrCVTermId.setGF(m_CurrCVTerm);
				m_CurrCVTerm = null;//CONSUME
				//System.out.println("++FSS CVTERM TYPE ID<"
				//		+((CVTerm)(m_CurrCVTermId.getGF())).getname()+">");
			}
			m_CurrCVTerm = null;//CONSUME
		}else if(qualifiedName.equals("cvterm_id")){
			//BUILD
			if(m_CurrCVTermId.getGF()==null){
				m_CurrCVTermId.setkey(m_SB.toString().trim());
				//System.out.println("\n=ASSIGNING CVTERM_ID <"
				//		+m_CurrCVTermId.getkey()+">");
			}
			//LOCATE
			if(m_CurrFeatCVTerm!=null){
				m_CurrFeatCVTerm.setCVTermId(m_CurrCVTermId);
				m_CurrCVTermId = null;//CONSUME
			}

		}else if(qualifiedName.equals("type_id")){
			//BUILD
			if(m_CurrTypeId.getGF()==null){
				m_CurrTypeId.setkey(m_SB.toString().trim());
			}
			//LOCATE
			Object o = null;
			try{
				o = m_CurrTypeStack.peek();
			}catch(Exception ex){
			}
			if(o!=null){
			 if(o instanceof Feature){
				String oldType = m_CurrFeature.getTypeId();
				m_CurrFeature.setTypeId(m_CurrTypeId);
				m_CurrTypeId = null;//CONSUME
			 }else if(o instanceof Pub){
				//System.out.println("TO Pub");
				m_CurrPub.setTypeId(m_CurrTypeId);
			 }else if(o instanceof Synonym){
				//System.out.println("TO Synonym");
			 }else if(o instanceof FeatRel){
				//System.out.println("TO Feature_Relationship");
			 }else if(o instanceof FeatProp){
				m_CurrFeatProp.setPkeyId(m_CurrTypeId);
				m_CurrTypeId = null;//CONSUME
				//System.out.println("FILL<"+m_CurrFeatProp.getPkeyId()+">");
			 }else{
				System.out.println("TO UNKNOWN");
				m_CurrTypeId = null;//CONSUME
			 }
			}
//END CVTERM,TYPE_ID,PKEY_ID

//CV
		}else if(qualifiedName.equals("cv_id")){
			//System.out.println("FINISH CV_ID");
			//BUILD
			//EITHER CONTAINS TEXT OR A PUB
			if(m_CurrCVId.getGF()==null){
				m_CurrCVId.setkey(m_SB.toString().trim());
			}
			//LOCATE
			//ONLY APPEARS IN A CVTERM
			if(m_CurrCVTerm!=null){
				m_CurrCVTerm.setCVId(m_CurrCVId);
				m_CurrCVId = null;//CONSUME
			}else{
				//System.out.println("CV_ID NOT PUT HERE, SO WHERE?");
			}
		}else if(qualifiedName.equals("cv")){
			//System.out.println("FINISH CV");
			//BUILD
			//LOCATE
			if(m_CurrCV!=null){
				//System.out.println("WWW<"
				//		+m_CurrCV.getcvname()+">");
				m_CVTERMname = m_CurrCV.getcvname();
			}
			if(m_CurrCVId!=null){
				//System.out.println("PUT IN CV_ID");
				//PUT IN SMART POINTER
				m_CurrCVId.setGF(m_CurrCV);
				//m_CurrCV = null;//CONSUME
			}else{
				//System.out.println("PUT ELSEWHERE");
			}
			m_CurrCV = null;//CONSUME

			//CV xxx =(CV)(m_CurrCVId.getGF());
			//if(xxx!=null){
			//	String ttt = xxx.getcvname();
			//	System.out.println("TTT<"+ttt+">");
			//}
//DB
		}else if(qualifiedName.equals("db_id")){
			//BUILD
			//EITHER CONTAINS TEXT OR A DB
			if(m_CurrDBId.getGF()==null){
				m_CurrDBId.setkey(m_SB.toString().trim());
			}
			//LOCATE
			//ONLY APPEARS IN A DBXREF
			if(m_CurrDbxref!=null){
				m_CurrDbxref.setDBId(m_CurrDBId);
				m_CurrDBId = null;//CONSUME
			}
		}else if(qualifiedName.equals("db")){
			//BUILD
			//LOCATE
			if(m_CurrDBId!=null){
				//PUT IN SMART POINTER
				m_CurrDBId.setGF(m_CurrDB);
				//m_CurrDB = null;//CONSUME
			}
			m_CurrDB = null;//CONSUME

//DBXREF 
		}else if(qualifiedName.equals("dbxref_id")){
			//BUILD
			if(m_CurrDbxrefId.getGF()==null){
				m_CurrDbxrefId.setkey(m_SB.toString().trim());
				//System.out.println("\t\t****SET dbxref_id KEY TO<"
				//		+m_SB.toString().trim()+">");
			}
			//LOCATE
			if(m_CurrFeatDbxref!=null){
				//System.out.println("\t\t****PUT dbxref_id INTO feat_dbxref");
				m_CurrFeatDbxref.setDbxrefId(m_CurrDbxrefId);
				m_CurrDbxrefId = null;//CONSUME
			}else if(m_CurrFeature!=null){
				//System.out.println("\t\t****PUT dbxref_id INTO feature ID<"
				//		+m_CurrFeature.getId()
				//		+"> NAME<"+m_CurrFeature.getName()+">");
				m_CurrFeature.setDbxrefId(m_CurrDbxrefId);
				m_CurrDbxrefId = null;//CONSUME
			}
			//System.out.println("\t\tEND dbxref_id");
		}else if(qualifiedName.equals("dbxref")){
			//BUILD

			//LOCATE
			if(m_CurrDbxrefId!=null){
				m_CurrDbxrefId.setGF(m_CurrDbxref);
				//System.out.println("\t\t\t***PUT DBXREF INTO DBXREF_ID KEY<"
				//	+m_CurrDbxrefId.getkey()+">");
				m_CurrDbxref = null;
			}
			//System.out.println("\t\t\tEND dbxref");

//ORGANISM
		}else if(qualifiedName.equals("organism_id")){
			//BUILD
			if(m_CurrOrganismId.getGF()==null){
				m_CurrOrganismId.setkey(m_SB.toString().trim());
			}
			//LOCATE
			if(m_CurrGenFeat!=null){
				m_CurrGenFeat.setOrganismId(m_CurrOrganismId);
				m_CurrOrganismId = null;//CONSUME
			}
		}else if(qualifiedName.equals("organism")){
			//BUILD
			//LOCATE
			if(m_CurrOrganismId!=null){
				//PUT IN SMART POINTER
				m_CurrOrganismId.setGF(m_CurrOrganism);
				m_CurrOrganism = null;
			}else if(m_CurrGenFeat!=null){
				m_CurrGenFeat.addAttrib(m_CurrOrganism);
				m_CurrOrganism = null;
			}else{
				m_CurrChado.addAttrib(m_CurrOrganism);
				m_CurrOrganism = null;
			}

//PUB
		}else if(qualifiedName.equals("pub_id")){
			//EITHER CONTAINS TEXT OR A PUB
			//BUILD
			if(m_CurrPubId.getGF()==null){
				m_CurrPubId.setkey(m_SB.toString().trim());
			}
			//LOCATE
//FSSNEW
			if(m_CurrFeatProp!=null){
				m_CurrFeatProp.setPubId(m_CurrPubId);
				m_CurrPubId = null;//CONSUME
//FSSNEW
			}else if(m_CurrFeatSyn!=null){
				m_CurrFeatSyn.setPubId(m_CurrPubId);
				m_CurrPubId = null;//CONSUME
			}else if(m_CurrFeatCVTerm!=null){
				m_CurrFeatCVTerm.setPubId(m_CurrPubId);
				m_CurrPubId = null;//CONSUME
			}
		}else if(qualifiedName.equals("pub")){
			//BUILD
			//LOCATE
			//System.out.println("END OF PUB TYPE<"+m_CurrPub.getTypeId()
			//		+"> UN<"+m_CurrPub.getuniquename()+">");
			if(m_CurrPubId!=null){
				//PUT IN SMART POINTER
				m_CurrPubId.setGF(m_CurrPub);
				m_CurrPub = null;
			}else if(m_CurrGenFeat!=null){
				//STAND ALONE
				m_CurrGenFeat.addAttrib(m_CurrPub);
				m_CurrPub = null;
			}else{
				//STAND ALONE
				m_CurrChado.addAttrib(m_CurrPub);
				m_CurrPub = null;
			}
			m_CurrTypeStack.pop();

//PUTTING PARAMETERS INTO OBJECTS
	//FEATURE
		}else if(qualifiedName.equals("name")){
			//COULD BE IN A VARIETY OF PLACES
			if(m_SB.toString()!=null){
				String nameStr = m_SB.toString().trim();
				//System.out.print("*****************NAME<"+nameStr+"> ");
				/****/
				if(m_CurrCV!=null){
					//System.out.println("CV");
					m_CurrCV.setcvname(nameStr);
				}else if(m_CurrCVTerm!=null){
					//System.out.println("CVTERM");
					m_CurrCVTerm.setname(nameStr);
				}else if(m_CurrSynonym!=null){
					//System.out.println("SYNONYM");
					m_CurrSynonym.setname(nameStr);
				}else if(m_CurrDB!=null){
					//System.out.println("DB");
					m_CurrDB.setdbname(nameStr);
				//}else if(m_CurrFeatSyn!=null){
				//	System.out.println("FEATSYN");
				//	m_CurrSynonym.setname(nameStr);
				}else if(m_CurrFeature!=null){
					//System.out.println("  FEATURE NAME<"+nameStr+">");
					m_CurrFeature.setName(nameStr);
				}else{
					//System.out.println("UNKNOWN");
					m_CurrGenFeat.setName(nameStr);
				}
			}
	//FEATURE
		}else if(qualifiedName.equals("uniquename")){
			if(m_SB.toString()!=null){
				if(m_CurrPub!=null){
					m_CurrPub.setuniquename(
							m_SB.toString().trim());
				}else if(m_CurrFeature!=null){
					m_CurrFeature.setUniqueName(
							m_SB.toString().trim());
				}
			}
	//FEATURE
		}else if(qualifiedName.equals("md5checksum")){
			if(m_SB.toString()!=null){
				m_CurrFeature.setMd5(
						m_SB.toString().trim());
			}
	//FEATURE
		}else if(qualifiedName.equals("residues")){
			if(m_SB.toString()!=null){
				m_CurrFeature.setResidues(
						m_SB.toString().trim());
			}
	//FEATURE
		}else if(qualifiedName.equals("timeaccessioned")){
			if(m_SB.toString()!=null){
				m_CurrFeature.settimeaccessioned(
						m_SB.toString().trim());
				//System.out.println("<<"
				//		+m_SB.toString().trim()+">>");
			}
	//FEATURE
		}else if(qualifiedName.equals("timelastmodified")){
			if(m_SB.toString()!=null){
				m_CurrFeature.settimelastmodified(
						m_SB.toString().trim());
				//System.out.println("<<"
				//		+m_SB.toString().trim()+">>");
			}
	//FEATURE
		}else if(qualifiedName.equals("timeexecuted")){
			if(m_SB.toString()!=null){
				m_CurrFeature.settimeexecuted(
						m_SB.toString().trim());
				//System.out.println("<<"
				//		+m_SB.toString().trim()+">>");
			}
	//FEATURE
		}else if(qualifiedName.equals("seqlen")){
			if(m_SB.toString()!=null){
				m_CurrFeature.setseqlen(
						m_SB.toString().trim());
			}

		}else if(qualifiedName.equals("rawscore")){
			if(m_SB.toString()!=null){
				if(m_CurrFeature!=null){
					m_CurrFeature.setrawscore(
						m_SB.toString().trim());
				}
			}
		}else if(qualifiedName.equals("program")){
			if(m_SB.toString()!=null){
				m_CurrFeatAnal.setprogram(
						m_SB.toString().trim());
			}
		}else if(qualifiedName.equals("sourcename")){
			if(m_SB.toString()!=null){
				m_CurrFeatAnal.setsourcename(
						m_SB.toString().trim());
			}
		}else if(qualifiedName.equals("programversion")){
			if(m_SB.toString()!=null){
				m_CurrFeatAnal.setprogramversion(
						m_SB.toString().trim());
			}
		}else if(qualifiedName.equals("is_analysis")){
			if(m_SB.toString()!=null){
				m_CurrFeature.setisanalysis(
						m_SB.toString().trim());
				//String m_OFFSET = "";
				//for(int i=0;i<(m_Stack.size()-1);i++){
				//	m_OFFSET += "\t";
				//}
				//System.out.println(m_OFFSET+" IS_ANALYSIS<"
				//		+m_CurrFeature.getisanalysis()
				//		+"> AT DEPTH<"+m_Stack.size()+">");
				if(m_Stack.size()==2){
					if((m_readMode==GameWriter.CONVERT_GENE)&&(m_CurrFeature.getisanalysis().equals("1"))){
						//System.out.println("++++SUPPRESS THIS!");
						m_isUseful = false;
					}else{
						m_isUseful = true;
					}
				}
			}

	//FEATURELOC AND SPAN
		}else if(qualifiedName.equals("fmin")){
			if(m_SB.toString()!=null){
				m_SpanStartTxt = m_SB.toString().trim();
			}
		}else if(qualifiedName.equals("fmax")){
			if(m_SB.toString()!=null){
				m_SpanEndTxt = m_SB.toString().trim();
			}

		}else if(qualifiedName.equals("strand")){
			if(m_SB.toString()!=null){
				m_CurrFeatLoc.setstrand(
						m_SB.toString().trim());
			}
		}else if(qualifiedName.equals("locgroup")){
			//displayType("FeatLoc:locgroup");
			if(m_SB.toString()!=null){
				m_CurrFeatLoc = (FeatLoc)m_CurrTypeStack.peek();
				m_CurrFeatLoc.setlocgroup(
						m_SB.toString().trim());
			}

		}else if(qualifiedName.equals("is_fmin_partial")){
			if(m_SB.toString()!=null){
				m_CurrFeatLoc.setnbegpart(
						m_SB.toString().trim());
			}

		}else if(qualifiedName.equals("is_fmax_partial")){
			if(m_SB.toString()!=null){
				m_CurrFeatLoc.setnendpart(
						m_SB.toString().trim());
			}

		}else if(qualifiedName.equals("rank")){
			//COULD BE EITHER
			//featureloc, feature_relationship, or featureprop
			FeatSub top = (FeatSub)m_CurrTypeStack.peek();
			if(m_SB.toString()!=null){
				String rank = m_SB.toString().trim();
				if(top==null){
					//System.out.println("rank IN NULL");
				}else if(top instanceof FeatProp){
					((FeatProp)top).setrank(rank);
				}else if(top instanceof FeatLoc){
					((FeatLoc)top).setrank(rank);
				}else{
					//System.out.println("rank IN feature_relationship");
				}
			}
		}else if(qualifiedName.equals("min")){
			if(m_SB.toString()!=null){
				m_CurrFeatLoc.setmin(
						m_SB.toString().trim());
			}
		}else if(qualifiedName.equals("max")){
			if(m_SB.toString()!=null){
				m_CurrFeatLoc.setmax(
						m_SB.toString().trim());
			}
		}else if(qualifiedName.equals("residue_info")){
			if(m_SB.toString()!=null){
				m_CurrFeatLoc.setresidue_info(
						m_SB.toString().trim());
			}

	//FEATURE_DBXREF,FEATURE_SYNONYM
		}else if(qualifiedName.equals("is_current")){
			//IS EITHER feature_dbxref,feature_synonym
			if(m_SB.toString()!=null){
				m_iscurrentTxt = m_SB.toString().trim();
			}

	//FEATURE_SYNONYM
		}else if(qualifiedName.equals("is_internal")){
			if(m_SB.toString()!=null){
				m_CurrFeatSyn.setisinternal(
						m_SB.toString().trim());
			}

	//FEATUREPROP
		//}else if(qualifiedName.equals("pval")){
		}else if(qualifiedName.equals("value")){
			if(m_SB.toString()!=null){
				m_CurrFeatProp.setpval(
						m_SB.toString().trim());
			}

	//DBXREF
		}else if(qualifiedName.equals("accession")){
			if(m_SB.toString()!=null){
				m_CurrDbxref.setaccession(
						m_SB.toString().trim());
				//System.out.println("\t\t\t\tSETTING ACCESSION<"
				//	+m_CurrDbxref.getaccession()
				//	+"> IN ID<"+m_CurrDbxref.getId()+">");
			}
	//ORGANISM
		}else if(qualifiedName.equals("genus")){
			if(m_SB.toString()!=null){
				m_CurrOrganism.setgenus(
						m_SB.toString().trim());
			}
	//ORGANISM
		}else if(qualifiedName.equals("species")){
			if(m_SB.toString()!=null){
				m_CurrOrganism.setspecies(
						m_SB.toString().trim());
			}
	//ORGANISM
		}else if(qualifiedName.equals("taxgroup")){
			if(m_SB.toString()!=null){
				m_CurrOrganism.settaxgroup(
						m_SB.toString().trim());
			}
	//PUB
		}else if(qualifiedName.equals("miniref")){
			if(m_SB.toString()!=null){
				m_CurrPub.setminiref(
						m_SB.toString().trim());
			}
	//UNUSED
		}else{
			//System.out.println("----UNUSED CHADO ELEMENT<"
			//		+qualifiedName+">");
		}
	}

	public void reportNotUsed(String the_attr,String the_text){
		System.out.println("TEXT <"+the_text+"> NOT USED IN <"
				+the_attr+">");
	}

	public void characters(char[] ch,int start,int length){
		m_SB.append(new String(ch,start,length));
	}

	public void displayType(String the_currPos){
		Object the_o = m_CurrTypeStack.peek();
		System.out.println("POSITION <"+the_currPos+">");
		if(the_o==null){
			System.out.println("****TYPE <NULL>");
		}else if(the_o instanceof Feature){
			System.out.println("****TYPE <Feature> ID<"
					+((Feature)the_o).getId()+">");
		}else if(the_o instanceof FeatLoc){
			System.out.println("****TYPE <FeatLoc> ID<"
					+((FeatLoc)the_o).getId()+">");
		}else if(the_o instanceof FeatProp){
			System.out.println("****TYPE <FeatProp> ID<"
					+((FeatProp)the_o).getId()+">");
		}else if(the_o instanceof FeatRel){
			System.out.println("****TYPE <FeatRel> ID<"
					+((FeatRel)the_o).getId()+">");
		}else if(the_o instanceof Synonym){
			System.out.println("****TYPE <Synonym> ID<"
					+((Synonym)the_o).getId()+">");
		}
	}

	public static void main(String args[]){
		ChadoSaxReader pd = new ChadoSaxReader();
		String fn = "../OUT/test.xml.chado1";
		pd.parse(fn,GameWriter.CONVERT_ALL);
		GenFeat topnode = pd.getTopNode();
		topnode.Display(0);
	}
}



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
//private SMTPTR m_CurrPkeyId;
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

private FeatSub m_CurrFeatEvid,m_CurrFeatCVTerm;
//private FeatEvid m_CurrFeatEvid;
//private FeatCVTerm m_CurrFeatCVTerm;

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

	public ChadoSaxReader(){
		super();
	}

	public void parse(String the_FilePathName,
			//boolean the_GeneOnly){
			int the_readMode){
		//m_GeneOnly = the_GeneOnly;
		m_readMode = the_readMode;
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
		return m_CurrChado;
	}


	public void startElement (String namespaceUri, String localName,
			String qualifiedName, Attributes attributes)
			throws SAXException {
		//System.out.println("MyHandler startElement");
		//System.out.println("NameSpaceURI<"+namespaceUri+">");
		//System.out.println("LocalName<"+localName+">");
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

		}else if(qualifiedName.equals("feature_synonym")){
			String idTxt = attributes.getValue("id");
			m_CurrFEATSUB = m_CurrFeatSyn = new FeatSyn(idTxt);
			//System.out.println("START FEATURE_SYNONYM");

		}else if(qualifiedName.equals("feature_cvterm")){
			String idTxt = attributes.getValue("id");
			m_CurrFEATSUB = m_CurrFeatCVTerm = new FeatSub(idTxt);

		}else if(qualifiedName.equals("analysis")){
			m_CurrFeatAnal = new FeatAnal("analysis");
			m_Stack.push(m_CurrFeature);

		}else if(qualifiedName.equals("synonym")){
			String idTxt = attributes.getValue("id");
			m_CurrSynonym = new Synonym(idTxt);
			m_CurrTypeStack.push(m_CurrSynonym);
			//System.out.println("  START SYNONYM");

		}else if(qualifiedName.equals("featureloc")){
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
			//System.out.println(" START SYNONYM_ID");
			m_CurrFEATID = m_CurrSynonymId = new SMTPTR("synonym");
			//FEATURE_SYNONYM

//START CVTERM,TYPE_ID,PKEY_ID
		}else if(qualifiedName.equals("cvterm_id")){
		}else if(qualifiedName.equals("type_id")){
			m_CurrTypeId = new SMTPTR("type");
		}else if(qualifiedName.equals("cvterm")){
			String idTxt = attributes.getValue("id");
			m_CurrCVTerm = new CVTerm(idTxt);

		/***************
		//DEFUNCT AS OF v7
		}else if(qualifiedName.equals("pkey_id")){
			m_CurrPkeyId = new SMTPTR("pkey");
		***************/
//END CVTERM,TYPE_ID,PKEY_ID

//CV
		}else if(qualifiedName.equals("cv_id")){
			//System.out.println("START CV_ID");
			m_CurrCVId = new SMTPTR("cv");

		}else if(qualifiedName.equals("cv")){
			String idTxt = attributes.getValue("id");
			//System.out.println("START CV");
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
		}else if(qualifiedName.equals("dbxref")){
			String idTxt = attributes.getValue("id");
			m_CurrDbxref = new Dbxref(idTxt);

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
		}
	}

	public void endElement(String namespaceUri,String localName,
				String qualifiedName){
		//System.out.println("LEAVING QualifiedName<"+qualifiedName+">");

		if(qualifiedName.equals("chado")){
			m_CurrChado.Display(0);
			//DO NOTHING

		}else if(qualifiedName.equals("_appdata")){
			if(m_SB.toString()!=null){
				m_CurrAppdata.setText(m_SB.toString().trim());
			}
			m_CurrChado.addGenFeat(m_CurrAppdata);

		}else if(qualifiedName.equals("feature")){
			GenFeat endingFeature = (GenFeat)m_Stack.pop();
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
				//System.out.println(" SAVING");
			}else{
				System.out.println(" NOT SAVING");
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
			Span tmpSpan = new Span(m_SpanStartTxt,m_SpanEndTxt);
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
			//}else{
			//	System.out.println("NULL SRC FEATURE ID");
			}
			//LOCATE
			if(m_CurrFeature!=null){
				if(m_CurrFeature.getFeatLoc()==null){
					m_CurrFeature.setFeatLoc(m_CurrFeatLoc);
				}else{
					m_CurrFeature.setAltFeatLoc(m_CurrFeatLoc);
				}
				m_CurrFeatLoc = null;
			}

		}else if(qualifiedName.equals("featureprop")){
			m_CurrFeatProp = (FeatProp)m_CurrTypeStack.pop();

			if(m_CurrPubId!=null){
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
				m_CurrFeature.addFeatDbxref(m_CurrFeatDbxref);
				m_CurrFeatDbxref = null;//CONSUME
			}

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


		//}else if(qualifiedName.equals("feature_id")){
		//	//m_CurrFEATID = null;
		//	//FEATURELOC
		}else if(qualifiedName.equals("srcfeature_id")){
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
			//LOCATE
			//if(m_CurrPkeyId!=null){
			//	m_CurrPkeyId.setGF(m_CurrCVTerm);
			//	m_CurrCVTerm = null;//CONSUME
			//}else if(m_CurrTypeId!=null){
			if(m_CurrTypeId!=null){
				m_CurrTypeId.setGF(m_CurrCVTerm);
				m_CurrCVTerm = null;//CONSUME
			}
			m_CurrCVTerm = null;//CONSUME
		}else if(qualifiedName.equals("cvterm_id")){

		}else if(qualifiedName.equals("type_id")){
			//BUILD
			if(m_CurrTypeId.getGF()==null){
				m_CurrTypeId.setkey(m_SB.toString().trim());
				//System.out.println("\n=ASSIGNING TYPE_ID <"
				//		+m_CurrTypeId.getkey()+">");
			}else{
				//System.out.println("\n=ASSIGNING TYPE_ID <"
				//		+m_CurrTypeId.getValue()+">");
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

		/**************
		//DEFUNCT AS OF v7
		}else if(qualifiedName.equals("pkey_id")){
			//BUILD
			if(m_CurrPkeyId.getGF()==null){
				m_CurrPkeyId.setkey(m_SB.toString().trim());
			}
			//LOCATE
			if(m_CurrFeatProp!=null){
				((FeatProp)m_CurrFeatProp).setPkeyId(m_CurrPkeyId);
			}
		**************/
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
			if(m_CurrCVId!=null){
				//System.out.println("PUT IN CV_ID");
				//PUT IN SMART POINTER
				m_CurrCVId.setGF(m_CurrCV);
//EEE
				//m_CurrCV = null;//CONSUME
			}else{
				//System.out.println("PUT ELSEWHERE");
			}
			m_CurrCV = null;//CONSUME

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
//EEE
				m_CurrDBId = null;//CONSUME
			}
		}else if(qualifiedName.equals("db")){
			//BUILD
			//LOCATE
			if(m_CurrDBId!=null){
				//PUT IN SMART POINTER
				m_CurrDBId.setGF(m_CurrDB);
//EEE
				//m_CurrDB = null;//CONSUME
			}
			m_CurrDB = null;//CONSUME

//DBXREF 
		}else if(qualifiedName.equals("dbxref_id")){
			//BUILD
			if(m_CurrDbxrefId.getGF()==null){
				m_CurrDbxrefId.setkey(m_SB.toString().trim());
			}
			//LOCATE
			if(m_CurrFeatDbxref!=null){
				m_CurrFeatDbxref.setDbxrefId(m_CurrDbxrefId);
				m_CurrDbxrefId = null;//CONSUME
			}else if(m_CurrFeature!=null){
				m_CurrFeature.setDbxrefId(m_CurrDbxrefId);
				m_CurrDbxrefId = null;//CONSUME
			}
		}else if(qualifiedName.equals("dbxref")){
			//BUILD

			//LOCATE
			if(m_CurrDbxrefId!=null){
				m_CurrDbxrefId.setGF(m_CurrDbxref);
				m_CurrDbxref = null;
			}

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
			if(m_CurrFeatSyn!=null){
				m_CurrFeatSyn.setPubId(m_CurrPubId);
				m_CurrPubId = null;//CONSUME
			}else if(m_CurrFeatCVTerm!=null){
				//m_CurrFeatCVTerm.setPubId(m_CurrPubId);
				m_CurrPubId = null;//CONSUME
			}
		}else if(qualifiedName.equals("pub")){
			//BUILD
			//LOCATE
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

//PUTTING PARAMETERS INTO OBJECTS
	//FEATURE
		}else if(qualifiedName.equals("name")){
			//COULD BE IN A VARIETY OF PLACES
			if(m_SB.toString()!=null){
				String nameStr = m_SB.toString().trim();
				//System.out.print("NAME<"+nameStr+"> OF ");
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
					//System.out.println("FEATURE");
					m_CurrFeature.setName(nameStr);
				}else{
					//System.out.println("UNKNOWN");
					m_CurrGenFeat.setName(nameStr);
				}
			}
	//FEATURE
		}else if(qualifiedName.equals("uniquename")){
			if(m_SB.toString()!=null){
				m_CurrFeature.setUniqueName(
						m_SB.toString().trim());
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
						System.out.println("++++SUPPRESS THIS!");
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



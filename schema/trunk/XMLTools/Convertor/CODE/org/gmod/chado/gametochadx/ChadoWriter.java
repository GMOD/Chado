//ChadoWriter
package org.gmod.chado.gametochadx;

//import org.gmod.chado.gametochadx.*;
import java.io.*;
/****
//JAVA3
import com.sun.xml.tree.*;
import com.sun.xml.parser.Parser;
****/

/****/
//JAVA4
import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.stream.*;
import javax.xml.transform.dom.*;
/****/

import org.w3c.dom.*;
import org.xml.sax.*;

import java.util.*;

public class ChadoWriter {

public static int WRITEALL = 0;
public static int WRITECHANGED = 1;

//private GenFeat m_TopNode;
private String m_NewREFSTRING = "";
private String m_OldREFSTRING = null;
private Span m_REFSPAN = null;

private String m_InFile = null;
private String m_OutFile = null;
private int m_parseflags = GameSaxReader.PARSEALL;
private int m_modeflags = WRITEALL;

//FOR BUILDING PREAMBLE
private HashSet m_CVList;
private HashSet m_CVTERMList;
private HashSet m_PUBList;
private HashSet m_EXONList;


private int m_ExonCount = 0;

	public ChadoWriter(String the_infile,String the_outfile,
			int the_parseflags,int the_modeflags){
		m_parseflags = the_parseflags;
		m_modeflags = the_modeflags;
		if((the_infile==null)||(the_outfile==null)){
			System.exit(0);
		}
		m_InFile = the_infile;
		m_OutFile = the_outfile;
		System.out.println("START G->C INFILE<"+m_InFile
				+"> OUTFILE<"+m_OutFile
				+"> FLAG<"+m_parseflags+">");
	}

	public void GameToChado(){
		GameSaxReader gsr = new GameSaxReader();
		gsr.parse(m_InFile,m_parseflags);
		GenFeat TopNode = gsr.getTopNode();
		System.out.println("DONE PARSING GAME FILE");
		writeFile(TopNode,m_OutFile);
		//TopNode.Display(0);
		System.out.println("DONE G->C INFILE<"+m_InFile
				+"> OUTFILE<"+m_OutFile+">\n");
	}

	public void writeFile(GenFeat gf,String the_filePathName){
		try{
			/**************/
			//JAVA1.4
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			factory.setValidating(true);
			factory.setIgnoringElementContentWhitespace(false);
			//factory.setCoalescing(true);
			DocumentBuilder builder = factory.newDocumentBuilder();
			DOMImplementation impl = builder.getDOMImplementation();
			Document m_DOC = impl.createDocument(null,"chado",null);
			Element root = makeChadoDoc(m_DOC,gf);

			DOMSource domSource = new DOMSource(m_DOC);
			StreamResult streamResult = new StreamResult(new FileWriter(the_filePathName));
			TransformerFactory transFactory = TransformerFactory.newInstance();
			Transformer trans = transFactory.newTransformer();
			trans.setOutputProperty(OutputKeys.ENCODING,"ISO-8859-1");
			trans.setOutputProperty(OutputKeys.INDENT,"yes");
			trans.setOutputProperty("{http://xml.apache.org/xslt}indent-amount","2");
			trans.transform(domSource,streamResult);
			/**************/
			/**************
			//JAVA1.3
			Document m_DOC = new Document();
			m_DOC.appendChild(makeChadoDoc(m_DOC,gf));
			Writer out = new OutputStreamWriter(new FileOutputStream(the_filePathName,false));
			m_DOC.write(out);
			out.flush();
			**************/
		}catch(Exception ex){
			ex.printStackTrace();
		}
	}


	public Element makeChadoDoc(Document the_DOC,GenFeat the_TopNode){
		Element root = the_DOC.getDocumentElement();

		//PREAMBLE
		storeCV("arm","feature type");
		storeCV("gene","feature type");
//KLUDGE
		storeCV("annot_sequence","feature type");
		storeCV("sequence","feature type");
		storeCV("mRNA","feature type");
		storeCV("UNKNOWN","feature type");
//KLUDGE
		preprocessCVTerms(the_TopNode);

		//CHANGED FEATURES

		if(m_modeflags==WRITECHANGED){
			//MARK ALL GENES WHICH HAVE BEEN LISTED AS CHANGED
			//AND GET ITS LIST OF NON ANNOT SEQUENCES
			//(FROM ITS 'produces_seq' TAG)
			Vector prodSeqList = new Vector();
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				GenFeat gf = the_TopNode.getGenFeat(i);
				if(gf instanceof ModFeat){
					if(gf.getType().startsWith("changed_gene")){
						System.out.println("CHANGED GENE");
						prodSeqList.addAll(
							markGeneAsChanged(
								the_TopNode,
								gf.getId()));
					}else{
						//DELETION DONE LATER
					}
				}
			}
			//NEED TO MARK ALL NON ANNOT SEQUENCES WHICH ARE
			//IN THE ABOVE prodSeqList VECTOR, KEEP THESE
			//AND THROW AWAY THE REST
			for(int i=0;i<prodSeqList.size();i++){
				String ps = (String)prodSeqList.get(i);
				System.out.println("NEED TO SAVE NAS<"+ps+">");
			}
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				GenFeat gf = the_TopNode.getGenFeat(i);
				if(gf instanceof Seq){
					if(prodSeqList.contains(gf.getId())){
						gf.setChanged(true);
					}
				}
			}
		}

		//TEST
		//Element testNode = (Element)the_DOC.createElement("test");
		//testNode.appendChild(the_DOC.createTextNode("\n"));
		//root.appendChild(testNode);

		root = makePreamble(the_DOC,root);

		//METADATA (map_position feature written below)
		if(the_TopNode.getArm()!=null){
			m_NewREFSTRING = the_TopNode.getArm();
			if(the_TopNode.getSpan()!=null){
				m_REFSPAN = the_TopNode.getSpan();
			}else{
				m_REFSPAN = new Span(1,1);
			}
		}

		//FIND NON ANNOT SEQ WITH FOCUS 'true' TO GET OLD REF STRING
		String tmpResidues = null;
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			//System.out.println("GENFEAT<"+gf.getId()
			//		+"> FOCUS<"+gf.getFocus()+">");
			if(gf instanceof Seq){
				if((gf.getFocus()!=null)
						&&(gf.getFocus().equals("true"))){
					m_OldREFSTRING = gf.getId();
					tmpResidues = gf.getResidues();
				}
			}
		}
		if(m_OldREFSTRING!=null){
			root.appendChild(makeAppdata(
					the_DOC,"arm",m_NewREFSTRING));
		}
		if(m_OldREFSTRING!=null){
			root.appendChild(makeAppdata(
					the_DOC,"title",m_OldREFSTRING));
		}
		if(m_REFSPAN!=null){
			root.appendChild(makeAppdata(
					the_DOC,"min",(""+m_REFSPAN.getStart())));
			root.appendChild(makeAppdata(
					the_DOC,"max",(""+m_REFSPAN.getEnd())));
		}
		if(tmpResidues!=null){
			root.appendChild(makeAppdata(
					the_DOC,"residues",tmpResidues));
		}

		//DELETE FEATURES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof ModFeat){
				//System.out.println("Make Mod Feat");
				if(gf.getType().startsWith("deleted_")){
					root.appendChild(makeDelFeat(the_DOC,gf));
				}else if(gf.getType().startsWith("changed_gene")){
					//DONE EARLIER
				}
			}
		}

//REFERENCE SEQUENCE
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			//System.out.println("GENFEAT<"+gf.getId()
			//		+"> FOCUS<"+gf.getFocus()+">");
			if(gf instanceof Seq){
				if((gf.getFocus()!=null)
					&&(gf.getFocus().equals("true"))){
					//System.out.println("WRITING THIS DOCS REFERENCE SEQUENCE\n\n");
					//root.appendChild(makeNonAnnotSeqFeat(
					//	the_DOC,gf,"annot_sequence"));
					//INSTEAD, WE SHOULD WRITE AN
					// _appdata FOR 'TITLE' and 'RESIDUES'
					m_OldREFSTRING = gf.getId();
				}
			}else if((gf instanceof Annot)
				||(gf instanceof ComputationalAnalysis)
				||(gf instanceof ModFeat)){
					//SAVE FOR LATER
			}else if(gf instanceof ModFeat){
					//DONE EARLIER
			}else{
				System.out.println("UNKNOWN FEATURE");
			}
		}

//ARM
		//REFERENCE FEATURE
		//ONLY ONE MAP_POSTION PER GAME FILE, REGARDLESS
		//OF HOW MANY ANNOTATIONS ARE THERE
		//System.out.println("NEW REFSTRING<"+m_NewREFSTRING
		//		+"> OLD REFSTRING<"+m_OldREFSTRING
		//		+"> REFSPAN<"+m_REFSPAN.toString()+">");
		root.appendChild(makeArmNode(the_DOC,m_NewREFSTRING));

//ANNOTATIONS, COMP_ANAL, AND NON ANNOT SEQUENCES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Annot){
				if((gf.isChanged())||(m_modeflags==WRITEALL)){
					root.appendChild(makeAnnotNode(the_DOC,gf));
				}
			}else if(gf instanceof ComputationalAnalysis){
				//System.out.println("WRITING COMP_ANALYSIS");
				root.appendChild(makeAnalysis(the_DOC,gf));
			}else if(gf instanceof Seq){
				System.out.println("WRITING NON ANNOT SEQUENCE FEAT<"+gf.getId()+"> WITH FOCUS<"+gf.getFocus()+">");
				if((gf.getFocus()==null)
						||(gf.getFocus().equals("false"))){
					if((gf.isChanged())||(m_modeflags==WRITEALL)){
						System.out.println("\tIS WRITTEN");
						root.appendChild(
							makeNonAnnotSeqFeat(
							the_DOC,gf,"sequence",
							null,null,null));
					}else{
						System.out.println("\tIS NOT WRITTEN");
						//NOT MARKED AS 'CHANGED'
						//MEANING THAT IT IS NOT
						//REFERENCED BY A GENE WHICH
						//IS LISTED AS CHANGED
					}
				}
			}else if(gf instanceof ModFeat){
				//DONE EARLIER
			}else{
				System.out.println("SOME UNKNOWN FEAT TYPE<"+gf.getId()+">\n");
			}
		}
		return root;
	}

	public Vector markGeneAsChanged(GenFeat topNode,String the_id){
		System.out.println("LOOKING FOR GENE WITH ID<"+the_id+">");
		Vector prodSeqList = new Vector();
		for(int i=0;i<topNode.getGenFeatCount();i++){
			GenFeat gf = topNode.getGenFeat(i);
			if(gf.getType()!=null){
				System.out.println("\tCHECKING GENE TYPE<"
					+gf.getType()+"> WITH ID<"
					+gf.getId()+">");
			if((gf.getType().equals("gene"))
					&&(gf.getId().equals(the_id))){
				System.out.println("\t\tSETTING GENE<"
						+the_id+"> TO TRUE");
				gf.setChanged(true);
				prodSeqList = gf.getProducedSequences();
			}
			}else{
				System.out.println("\tCHECKING GENE <"
						+gf.getId()+"> WITH NULL TYPE");
			}
		}
		return prodSeqList;
	}

	public Element makeAppdata(Document the_DOC,
			String the_name,String the_data){
		Element appdataNode = (Element)the_DOC.createElement("_appdata");
		appdataNode.setAttribute("name",the_name);
		appdataNode.appendChild(the_DOC.createTextNode(the_data));
		return appdataNode;
	}

	public Element makeArmNode(Document the_DOC,String the_ArmSTRING){
		Element RefFeatNode = (Element)the_DOC.createElement("feature");
		RefFeatNode.setAttribute("id",the_ArmSTRING);

		//UNIQUENAME
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"uniquename",the_ArmSTRING));

		//ORGANISM_ID
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"organism_id","Dmel"));

		//TYPE_ID
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id","arm"));
		return RefFeatNode;
	}

	public Element makeAnnotNode(Document the_DOC,GenFeat gf){
		Element GeneFeatNode = (Element)the_DOC.createElement("feature");
		GeneFeatNode = makeFeatHeader(the_DOC,gf,GeneFeatNode,null);
		//System.out.println("START ANNOT NODE");
		//ASPECT
		for(int j=0;j<gf.getGenFeatCount();j++){
			GenFeat agf = gf.getGenFeat(j);
			if(agf instanceof Aspect){
				//System.out.println("\tWRITING ASPECT");
				GeneFeatNode.appendChild(
					makeFeatCVTerm(the_DOC,(Aspect)agf));
			}
		}

		//CALCULATE FEATLOC's FOR TRANSCRIPT AND GENES FROM EXONS
		Span geneSpan = null;
		System.out.println("CALCULATING UNION FOR<"+gf.getId()+">");
		for(int i=0;i<gf.getGenFeatCount();i++){
			GenFeat tran = gf.getGenFeat(i);
			if(tran instanceof FeatureSet){
			if(tran.getType()==null){
				if(gf.getType()!=null){
					tran.setType(gf.getType());
				}else if((tran.getName()!=null)
						&&(tran.getName().indexOf("-R")>0)){
					tran.setType("transcript");
				}
			}
			if((tran.getType().equals("transcript"))
				||(tran.getType().equals("transposable_element"))){
				Span tranSpan = null;
				for(int j=0;j<tran.getGenFeatCount();j++){
					GenFeat exon = tran.getGenFeat(j);
					System.out.println("EXON TYPE<"+exon.getType()+"> ID<"+exon.getId()+">");
					if(exon instanceof FeatureSpan){
					System.out.println("IS INDEED EXON");
					if(exon.getType()==null){
						exon.setType("exon");
					}
					if(exon.getType().equals("start_codon")){
						Span protSpan = exon.getSpan();
						protSpan = protSpan.advance(m_REFSPAN.getStart());
						protSpan.setSrc(m_NewREFSTRING);
						exon.setSpan(protSpan);
					}else if(exon.getType().equals("exon")){
						Span exonSpan = exon.getSpan();
						exonSpan = exonSpan.advance(m_REFSPAN.getStart());
						exonSpan.setSrc(m_NewREFSTRING);
						exon.setSpan(exonSpan);
						if(tranSpan==null){
							tranSpan=exonSpan;
						}else{
			//System.out.print("UNION OF <"+tranSpan+"> AND <"+exon.getSpan()+"> IS<");
							tranSpan = tranSpan.union(
								exonSpan);
			//System.out.println(tranSpan+">");
						}
					}
					}
				}
				if(tranSpan!=null){
				//tranSpan = tranSpan.advance(
				//		m_REFSPAN.getStart());
				tranSpan.setSrc(m_NewREFSTRING);
				tran.setSpan(tranSpan);
				if(geneSpan==null){
					geneSpan = tranSpan;
				}else{
			System.out.print("\tUNION OF <"+geneSpan+"> AND <"+tranSpan+"> IS<");
					geneSpan = geneSpan.union(tranSpan);
			System.out.println(geneSpan+">");
				}
				}
			}
			}
		}
		if(geneSpan!=null){
			geneSpan.setSrc(m_NewREFSTRING);
		}
		gf.setSpan(geneSpan);

		//FEATLOC
		if(gf.getSpan()!=null){
			GeneFeatNode.appendChild(
					makeFeatureLoc(the_DOC,gf.getSpan()));
		}

		//FEATURE_SET
		for(int j=0;j<gf.getGenFeatCount();j++){
			GenFeat fsgf = gf.getGenFeat(j);
			if(fsgf instanceof FeatureSet){
				//System.out.println("\tWRITING FEATURE_SET");
				m_ExonCount = 0;
				GeneFeatNode.appendChild(
						makeFeatRel(the_DOC,"contains",
						makeFeatBodyNode(the_DOC,fsgf,
								null)));
			}
		}
		//System.out.println("DONE ANNOT NODE");
		return GeneFeatNode;
	}

	public Element makeSeqNode(Document the_DOC,GenFeat the_gf,
			String the_parentName,
			Span firstSpan,Span secondSpan){
		System.out.println("MAKE_SEQ_NODE<"
				+the_gf.getId()
				+"> PARENT<"+the_parentName
				+"> TYPE<"+the_gf.getType()+">");
		return makeNonAnnotSeqFeat(the_DOC,the_gf,
				the_gf.getType(),the_parentName,
				firstSpan,secondSpan);
	}


	public Element makeNonAnnotSeqFeat(Document the_DOC,
				GenFeat the_gf,String the_seqType,
				String the_parentName,
				Span firstSpan,Span secondSpan){
		//System.out.println("START NON_ANNOT_SEQ NODE");
		Element seqFeatNode = (Element)the_DOC.createElement("feature");

		//ATTRIBUTES
		String seqId = the_gf.getId();
		String seqName = the_gf.getName();
		if(seqId==null){
			seqId = seqName;
		}

		if((the_parentName!=null)
				&&(seqId!=null)
				&&(seqId.startsWith(the_parentName))){
			if(the_seqType.equals("aa")){
				System.out.print("TEXTREPLACE<"+seqId);
				seqId = textReplace(seqId,"-R","-P");
				System.out.println("> WITH<"+seqId+">");
			}
		}
		//ID
		//if(seqId!=null){
		//	seqFeatNode.setAttribute("id",seqId);
		//}
		if(seqName!=null){
			seqFeatNode.setAttribute("id",seqName);
		}else{
			seqFeatNode.setAttribute("id",seqId);
		}

		//NAME
		if((the_parentName!=null)
				&&(seqName.startsWith(the_parentName))){
			if(the_seqType.equals("aa")){
				seqName = textReplace(seqName,"-R","-P");
			}
		}
		if(seqName!=null){
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"name",seqName));
		}

		//UNIQUENAME
		String uniquename = seqName;
		if(uniquename==null){
			uniquename = seqId;
		}
		seqFeatNode.appendChild(makeGenericNode(
				the_DOC,"uniquename",uniquename));

		//ORGANISM_ID
		seqFeatNode.appendChild(makeGenericNode(
				the_DOC,"organism_id","Dmel"));

		//MD5CHECKSUM
		if(the_gf.getMd5()!=null){
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"md5checksum",the_gf.getMd5()));
		}

		//TYPE_ID
		if(the_seqType!=null){
			if(the_seqType.equals("aa")){
				seqFeatNode.appendChild(makeGenericNode(
						the_DOC,"type_id","protein"));
			}else{
				seqFeatNode.appendChild(makeGenericNode(
						the_DOC,"type_id",the_seqType));
			}
		}

		//SEQLEN
		if(the_gf.getResidueLength()!=null){
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"seqlen",the_gf.getResidueLength()));
		}

		//DBXREF_ID
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					seqFeatNode.appendChild(
						makeDbxrefIdAttrNode(
							the_DOC,attr));
				}
			}
		}

		//RESIDUES
		if(the_gf.getResidues()!=null){
			//System.out.println("\tRESIDUES OF LEN<"
			//		+the_gf.getResidues().length()+">");
			seqFeatNode.appendChild(makeGenericNode(the_DOC,
					"residues",the_gf.getResidues()));
		}else{
/*********************************
//RESIDUES_LENGTH
//SHOULD INSTEAD SET <seqlen> FOR <feature>
			//System.out.println("\tRESIDUES OF LEN<0>");
			//NO RESIDUES, NEED TO CREATE ATTRIB FOR LENGTH INFO
			seqFeatNode.appendChild(
				makeGameTempStorage(the_DOC,
						"sequence_length",
						the_gf.getResidueLength()));
*********************************/
		}

		//SPANS
		if(firstSpan!=null){
			seqFeatNode.appendChild(makeFeatureLoc(
					the_DOC,firstSpan));
		}

		/************
		//DISABLED FOR NOW
		if(secondSpan!=null){
			seqFeatNode.appendChild(makeFeatureLoc(
					the_DOC,secondSpan));
		}
		************/


		//DESCRIPTION
		if(the_gf.getDescription()!=null){
			seqFeatNode.appendChild(
				makeGameTempStorage(the_DOC,
						"description",
						the_gf.getDescription()));
		}


		//System.out.println("END NON_ANNOT_SEQ NODE");
		return seqFeatNode;
	}

	public String textReplace(String the_str,String the_old,String the_new){
		if((the_str==null)||(the_old==null)||(the_new==null)){
			return null;
		}
		int indx = the_str.indexOf(the_old);
		if(indx>=0){
			String firstPart = the_str.substring(0,indx);
			String lastPart = the_str.substring(indx+the_old.length());
			return firstPart+the_new+lastPart;
		}
		return the_str;
	}

	public String baseName(String the_name){
		if(the_name==null){
			return null;
		}
		int indx = the_name.indexOf("-R");
		if(indx>=0){
			String firstPart = the_name.substring(0,indx);
			return firstPart;
		}
		return the_name;
	}

	public Element makeDelFeat(Document the_DOC,GenFeat the_gf){
		//System.out.println("MOD FEAT<"+the_gf.getId()+">\n");
		Element modfeatNode = (Element)the_DOC.createElement("feature");
		modfeatNode.setAttribute("op","delete");

		//ID
		if(the_gf.getId()!=null){
			//modfeatNode.setAttribute("ref","GB:"+the_gf.getId());
			modfeatNode.setAttribute("ref","Gadfly:"+the_gf.getId());
		}

		/********************
		//UNIQUENAME
		String uniquename = the_gf.getName();
		if(uniquename==null){
			uniquename = the_gf.getId();
		}
		modfeatNode.appendChild(makeGenericNode(
				the_DOC,"uniquename",uniquename));

		//ORGANISM_ID
		modfeatNode.appendChild(makeGenericNode(
				the_DOC,"organism_id","Dmel"));

		//TYPE_ID
		String typStr = "";
		if(the_gf.getType()!=null){
			if(the_gf.getType().endsWith("gene")){
				typStr = "gene";
			}else if(the_gf.getType().endsWith("transcript")){
				//typStr = "transcript";
				typStr = "mRNA";
			}
			modfeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id",typStr));
		}
		********************/
		return modfeatNode;
	}

	public Element makeAnalysis(Document the_DOC,GenFeat the_gf){
		//COMPUTATIONAL_ANALYSIS
		Element analysis = (Element)the_DOC.createElement("analysis");
		if(the_gf.getProgram()!=null){
			analysis.appendChild(makeGenericNode(
					the_DOC,"program",the_gf.getProgram()));
		}
		analysis.appendChild(makeGenericNode(
				the_DOC,"programversion","0"));
		analysis.appendChild(makeGenericNode(
				the_DOC,"sourcename",the_gf.getDatabase()));

		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			//RESULT_SET
			if(gf==null){
				System.out.println("RESULT SET IS NULL!!!!!!!!!!!!");
			}
			Element analysisfeature = (Element)the_DOC.createElement("analysisfeature");
			analysisfeature.appendChild(makeAnalFeat(the_DOC,gf));
			analysis.appendChild(analysisfeature);
		}
		return analysis;
	}

	public Element makeFeatCVTerm(Document the_DOC,Aspect the_gf){
		Element featureCVTerm = (Element)
				the_DOC.createElement("feature_cvterm");
		Element CVTermId = (Element)the_DOC.createElement("cvterm_id");
		Element CVTerm = (Element)the_DOC.createElement("cvterm");
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					if(attr.getdb_xref_id().startsWith("GO:")){
						CVTerm.setAttribute("id",attr.getdb_xref_id());
						break;//EXPECT THERE TO BE ONLY ONE
					}
				}
			}
		}

		Element CVId = (Element)the_DOC.createElement("cv_id");
		Element termname = (Element)the_DOC.createElement("name");
		if(the_gf.getFunction()!=null){
			CVId.appendChild(the_DOC.createTextNode("molecular_function"));
			termname.appendChild(the_DOC.createTextNode(the_gf.getFunction()));
		}else{//cellular process,biological component
		}
		CVTerm.appendChild(CVId);
		CVTerm.appendChild(termname);

		CVTermId.appendChild(CVTerm);
		featureCVTerm.appendChild(CVTermId);
		//PUB
		featureCVTerm.appendChild(makeGenericNode(
				the_DOC,"pub_id","Gadfly"));
		return featureCVTerm;
	}

	public Element makeFeatRel(Document the_DOC,String the_relType,Element the_el){
		//System.out.println("\tSTART FEAT_REL");
		Element featrel = (Element)the_DOC.createElement("feature_relationship");
		//REL TYPE_ID
		featrel.appendChild(makeGenericNode(
				the_DOC,"type_id",the_relType));

		//REL SUBJ_FEATURE
		Element subjfeat = (Element)the_DOC.createElement("subjfeature_id");
		subjfeat.appendChild(the_el);
		featrel.appendChild(subjfeat);
		//System.out.println("\tDONE FEAT_REL");
		return featrel;
	}

	public Element makeFeatBodyNode(Document the_DOC,GenFeat the_gf,
			String the_parentName){
		//System.out.println("\tSTART FEAT_BODY");
		Element FeatNode = (Element)the_DOC.createElement("feature");
		FeatNode = makeFeatHeader(the_DOC,the_gf,FeatNode,
				the_parentName);
		//FEATURE_RELATIONSHIP
		//Span startCodonSpan = null;
		//Span wrtTransSpan = new Span(3,4,the_gf.getName());
		Span transSpan = null;
		if(the_gf instanceof FeatureSet){
			transSpan = the_gf.getSpan();
		}
		String transRes = null;
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			if(gf instanceof Annot){ //SHOULD NEVER SEE HERE
				System.out.println("SHOULDNOTSEETHISEITHER");
				FeatNode.appendChild(
						makeFeatRel(the_DOC,"contains",
						makeFeatBodyNode(the_DOC,gf,
						the_gf.getName())));
			}else if(gf instanceof FeatureSet){
				if(gf.getType()==null){
					System.out.println("NEEDTOGUESSTYPE");
				}
				FeatNode.appendChild(
						makeFeatRel(the_DOC,"contains",
						makeFeatBodyNode(the_DOC,gf,
						the_gf.getName())));
			}else if(gf instanceof FeatureSpan){
				System.out.println("###TYPE<"+gf.getType()+">");
				if(gf.getType()==null){
					//NO TYPE GIVEN FOR SPAN - GUESS
					if(the_gf.getType().equals("transposable_element")){
						//PARENT IS TYPE 'TE'
						gf.setType(the_gf.getType());
						System.out.println("PTAA");
					}else if(gf.getId().startsWith("TE")){
						//PARENT IS TYPE 'TE' BY NAME
						gf.setType("transposable_element");
						System.out.println("PTBB");
					}else if(the_gf.getType().equals("transcript")){
						//PARENT IS transcript
						//EITHER exon OR start_codon
						if(gf.getSpan().getLength()==3){
							gf.setType("start_codon");
						}else{
							gf.setType("exon");
						}
						System.out.println("PTCC");
					}else{
						//SOL
						System.out.println("SHOULDNOTSEE");
						gf.setType("UNKNOWN_TYPE");
						System.out.println("PTDD");
					}
				}
				System.out.println("TYPENOW<"+gf.getType()+">");

				if(gf.getType().equals("start_codon")){
					Span startCodonSpan = gf.getSpan();
					System.out.println("THIS CODON SPAN<"
							+startCodonSpan+">");

				}else if(gf.getType().equals("exon")){
					System.out.println("###TYPE<"
							+gf.getType()+"> SPAN<"
							+gf.getSpan()+"> LEN<"
							+gf.getSpan().getLength()+">");
					FeatNode.appendChild(
						makeFeatRel(the_DOC,"contains",
						makeFeatBodyNode(the_DOC,gf,
						the_gf.getName())));
				}else{
					FeatNode.appendChild(
						makeFeatRel(the_DOC,"contains",
						makeFeatBodyNode(the_DOC,gf,
						the_gf.getName())));
				}
			}else if(gf instanceof Seq){
				if(gf.getType()==null){
					//NO TYPE GIVEN FOR SEQ - GUESS
					if(gf.getResidues()!=null){
						String res = gf.getResidues().substring(0,1);
						System.out.println("SAMPLERES<"
							+res+">");
						if(res.equals("A")
							||res.equals("C")
							||res.equals("G")
							||res.equals("T")
							||res.equals("a")
							||res.equals("c")
							||res.equals("g")
							||res.equals("t")){
							gf.setType("cdna");
						}else{
							gf.setType("aa");
						}
			
					}
				}
				System.out.println("SEQTYPE<"+gf.getType()+">");

				if(gf.getType().equals("cdna")){
					transRes = cleanString(gf.getResidues());
					//System.out.println("TRANSRES<"+transRes
					//		+"> LEN<"+transRes.length()+">");
				}else if(gf.getType().equals("aa")){
					System.out.println("THIS LEN<"
						+gf.getResidueLength()+"> RES<"
						+gf.getResidues().length()+">");
					//int protLen = getProtLen(gf.getResidueLength(),gf.getResidues());
					//System.out.println("THIS PROTEIN LENGTH<"+protLen+">");
					Span wrtArmSpan = gf.getSpan().advance(m_REFSPAN.getStart());
					wrtArmSpan.setSrc(m_NewREFSTRING);
					Span wrtTransSpan = null;
					if(transSpan!=null){
						if(wrtArmSpan.isForward()){
							wrtTransSpan = wrtArmSpan.retreat(transSpan.getStart());
						}else{
							wrtTransSpan = wrtArmSpan.advance(transSpan.getEnd());
						}
						wrtTransSpan.setSrc(the_gf.getName());

/*******************
						Ribosome r = new Ribosome();
						String tranStr = r.getTranscript(
							transRes,
							wrtTransSpan.getStart(),
							wrtTransSpan.getEnd());
						System.out.println("TRUNC_TRAN_STR TO<"
								+wrtTransSpan.toString()
								+"> LEN<"
								+wrtTransSpan.getLength()
								+"> NEW RES<"
								+tranStr+">");
						if(tranStr!=null){
							String translationStr = r.translate(
								tranStr,
								Ribosome.DEF_TRANS_TYPE);
							System.out.println("PROT_STR LEN<"+translationStr.length()+"> AA<"+translationStr+">");
						}
*******************/
						FeatNode.appendChild(
							makeFeatRel(the_DOC,"produces",
							makeSeqNode(the_DOC,gf,the_gf.getName(),wrtArmSpan,wrtTransSpan)));
					}
				}else{
					System.out.println("SHLDNTSEE UNK TYPE");
				}
			}else{//COMP_ANAL/RESULT_SET/SPAN
				System.out.println("SHOULD NEVER SEE THIS??");
				FeatNode.appendChild((Element)
					the_DOC.createElement("analysis"));
			}
		}
		//System.out.println("\tDONE FEAT_BODY");
		return FeatNode;
	}

	public int getProtLen(String the_len,String the_residue){
		int protLen = 0;
		if(the_len!=null){
			try{
				protLen = Integer.decode(the_len).intValue();
			}catch(Exception ex){
			}
		}
		if((protLen==0)&&(the_residue!=null)){
			return the_residue.length();
		}else{
			return protLen;
		}
	}

	public Element makeFeatHeader(Document the_DOC,
			GenFeat the_gf,Element the_FeatNode,
			String the_parentName){
		//System.out.println("START FEAT_HEADER");
		//ID
		String idTxt = null;
		if(the_gf.getId()!=null){
			idTxt = the_gf.getId();
		}

		//PREPROCESS TYPE_ID
		String tmpTypeId = "UNKNOWN";
		if(the_gf.getType()!=null){
			tmpTypeId = the_gf.getType();
		}else if(the_gf.getId().indexOf("-R")>0){
			tmpTypeId = "mRNA";
		}else if(the_gf.getId().indexOf(":")>0){
			tmpTypeId = "exon";
		//}else{
		//	tmpTypeId = "UNKNOWN";
		}

		//CONVERT GAME TYPES TO CHADO TYPES
		if(tmpTypeId.equals("transcript")){
			tmpTypeId = "mRNA";
		}else if(tmpTypeId.equals("aa")){
			tmpTypeId = "protein";
		}

		//MUNGE THE NAMES FOR start_codonS WHICH ARE NOT UNIQUE
		if(tmpTypeId.equals("start_codon")){
			idTxt = idTxt+"_start_codon";
		}else if(tmpTypeId.startsWith("translate")){
			idTxt = idTxt+"_start_codon";
			//idTxt = idTxt+"_transl";
		}

		//ID
		if(idTxt!=null){
			the_FeatNode.setAttribute("id",idTxt);
		}

		//NAME
		if(the_gf.getName()!=null){
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		//UNIQUENAME
		String uniquename = idTxt;
		/*******************/
		if(uniquename==null){
				the_parentName = baseName(the_parentName);
			if(the_gf.getType().equals("exon")){
				m_ExonCount++;
				uniquename = the_parentName+":"+m_ExonCount;
			}else if(the_gf.getType().equals("start_codon")){
				uniquename = the_parentName+"_start_codon";
			}else{
				uniquename = the_parentName+"UNKNOWN";
			}
		}
		/*******************/
		if(uniquename!=null){
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"uniquename",uniquename));
		}

		//ORGANISM_ID
		the_FeatNode.appendChild(makeGenericNode(
				the_DOC,"organism_id","Dmel"));

		//MD5CHECKSUM
		/*****************/
		if(the_gf instanceof FeatureSet){
			for(int i=0;i<the_gf.getGenFeatCount();i++){
				GenFeat gf = the_gf.getGenFeat(i);
				if((gf.getType()!=null)
						&&(gf.getType().equals("cdna"))){
					//STORE THE RESIDUES MD5 HERE
					if(gf.getMd5()!=null){
						the_FeatNode.appendChild(
							makeGenericNode(the_DOC,
								"md5checksum",
								gf.getMd5()));
					}
				}
			}
		}
		/*****************/

		//TYPE_ID
		if(tmpTypeId!=null){
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id",tmpTypeId));
		}

		/**************
		//TIMESTAMP
		if(the_gf.gettimestamp()!=null){
			the_FeatNode.appendChild(makeChadoTimestampNode(
					the_DOC,the_gf.gettimestamp()));
		}
		**************/
		/**************
		//DATE
		if(the_gf.gettimestamp()!=null){
			Element time = (Element)the_DOC.createElement("timeaccessioned");
			time.appendChild(the_DOC.createTextNode(the_gf.gettimestamp()));
			the_FeatNode.appendChild(time);
		}
		**************/

		//DBXREF_ID
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					if(attr.getdb_xref_id().startsWith("FBgn")){
						the_FeatNode.appendChild(
							makeDbxrefIdAttrNode(
								the_DOC,attr));
					}
				}
			}
		}

		//FEATURE_DBXREF
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					if(!(attr.getdb_xref_id().startsWith("FBgn"))){
						the_FeatNode.appendChild(makeFeatureDbxrefAttrNode(the_DOC,attr));
					}
				}
			}
		}

		//RESIDUES
		if(the_gf instanceof FeatureSet){
			for(int i=0;i<the_gf.getGenFeatCount();i++){
				GenFeat gf = the_gf.getGenFeat(i);
				if((gf.getType()!=null)
						&&(gf.getType().equals("cdna"))){
					//WRITE THE RESIDUE AS THIS FEAT'S
					the_FeatNode.appendChild(
						makeGenericNode(the_DOC,
							"residues",
							gf.getResidues()));
				}
			}
		}

		//AUTHOR
		if(the_gf.getAuthor()!=null){
			the_FeatNode.appendChild(makeFeaturePropNode(
					the_DOC,"author",the_gf.getAuthor()));
		}

		//PROPERTY WHICH IS A protein_id
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("property")){
					//TYPE="protein_id"THEN IT BECOMES A
					//	<feature_dbxref><dbxref_id>
					//	"SP:"+getvalue()<><>
					if(attr.gettype().equals("protein_id")){
						//MAY NEED TO BE DEFERRED UNTIL AFTER
						//THE FEATURE_RELATIONSHIP!
						the_FeatNode.appendChild(
							makeFeaturePropAttrNode(the_DOC,attr));
					}
				}
			}
		}
		//PROPERTY WHICH IS NOT A protein_id
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("property")){
					//TYPE="protein_id"THEN IT BECOMES A
					//	<feature_dbxref><dbxref_id>
					//	"SP:"+getvalue()<><>
					if(!(attr.gettype().equals("protein_id"))&&(!(attr.gettype().equals("internal_synonym")))){
						the_FeatNode.appendChild(makeFeaturePropAttrNode(the_DOC,attr));
					}
				}
			}
		}
		//COMMENT
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("comment")){
					the_FeatNode.appendChild(makeCommentAttrNode(the_DOC,attr));
				}
			}
		}

		//INTERNAL SYNONYM FROM GAME internal_synonym PROPERTY
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("property")){
					if(attr.gettype().equals("internal_synonym")){
						the_FeatNode.appendChild(makeFeatureSynonym(the_DOC,attr.getvalue(),"1",the_gf.getAuthor()));
					}
				}
			}
		}

		//EXPLICIT SYNONYM 
		if((idTxt!=null)&&(the_gf.getName()!=null)
				&&(!(idTxt.equals(the_gf.getName())))){
			the_FeatNode.appendChild(makeFeatureSynonym(the_DOC,the_gf.getName(),"0",the_gf.getAuthor()));
		}

		//FEATLOC
		if(the_gf.getSpan()!=null){
			the_FeatNode.appendChild(makeFeatureLoc(the_DOC,the_gf.getSpan()));
		}
		if(the_gf.getAltSpan()!=null){
			the_FeatNode.appendChild(makeFeatureLoc(the_DOC,the_gf.getAltSpan()));
		}

		//System.out.println("DONE FEAT HEADER");
		return the_FeatNode;
	}

	public Element makeFeatureSynonym(Document the_DOC,String the_synonymTxt,String the_internalFlag,String the_Author){
		Element fsNode = (Element)the_DOC.createElement("feature_synonym");
		fsNode.appendChild(makeGenericNode(the_DOC,"is_internal",the_internalFlag));
		//SYNONYM_ID
		Element synIdNode = (Element)the_DOC.createElement("synonym_id");
		Element synNode = (Element)the_DOC.createElement("synonym");
		synNode.appendChild(makeGenericNode(the_DOC,"name",the_synonymTxt));
		synNode.appendChild(makeGenericNode(the_DOC,"synonym_sgml",the_synonymTxt));
		synNode.appendChild(makeGenericNode(the_DOC,"type_id","synonym"));
		synIdNode.appendChild(synNode);
		fsNode.appendChild(synIdNode);
//FSS
		//PUB_ID
		String pubId = "curated genome annotation";
		if(the_Author!=null){
			pubId = the_Author;//+" "+pubId;
		}else{
			pubId = "GadFly";//+" "+pubId;
		}
		fsNode.appendChild(makeGenericNode(the_DOC,"pub_id",pubId));
		fsNode.appendChild(makeGenericNode(the_DOC,"is_current","1"));
		return fsNode;
	}
/*************
<feature_synonym id="feature_synonym_23551">
	<is_internal>0</is_internal>
		<synonym_id>
			<synonym id="synonym_23551">
				<name>CG4491-RA</name>
				<type_id>
					<cvterm id="cvterm_59">
						<name>synonym</name>
						<cv_id>
							<cv id="cv_6">
								<cvname>synonym type</cvname>
							</cv>
						</cv_id>
					</cvterm>
				</type_id>
			</synonym>
		</synonym_id>
		<pub_id>
		<pub id="pub_1">
			<miniref>gadfly3</miniref>
		</pub>
	</pub_id>
	<is_current>0</is_current>
</feature_synonym>
<feature_synonym id="feature_synonym_23549">
	<is_internal>0</is_internal>
	<synonym_id>
		<synonym id="synonym_23549">
			<name>noc</name>
			<type_id>cvterm_59</type_id>
		</synonym>
	</synonym_id>
	<pub_id>pub_1</pub_id>
	<is_current>0</is_current>
</feature_synonym>
*************/

	public Element makeGenericNode(Document the_DOC,
			String the_type,String the_text){
		Element genNode = (Element)the_DOC.createElement(the_type);
		if(the_text!=null){
			genNode.appendChild(the_DOC.createTextNode(the_text));
		}
		return genNode;
	}

	//PUT IN ITS OWN FUNCTION AS PREPROCESSING MAY BE NEEDED LATER
	public Element makeChadoTimestampNode(Document the_DOC,
			String the_timestamp){
		Element tsNode = (Element)the_DOC.createElement("timeaccessioned");
		tsNode.appendChild(the_DOC.createTextNode(the_timestamp));
		return tsNode;
	}

	public Element makeFeaturePropNode(Document the_DOC,
			String the_pkey_id,String the_pval){
		Element fpNode = (Element)the_DOC.createElement("featureprop");
		if(the_pkey_id!=null){
			fpNode.appendChild(makeGenericNode(
					the_DOC,"pkey_id",the_pkey_id));
		}
		if(the_pval!=null){
			fpNode.appendChild(makeGenericNode(
					the_DOC,"pval",the_pval));
		}
		return fpNode;
	}

	public Element makeFeaturePropAttrNode(Document the_DOC,
			Attrib the_attr){
		String prefix = null;
		Element atNode = (Element)the_DOC.createElement("featureprop");
		if(the_attr.gettype()!=null){
			atNode.appendChild(makeGenericNode(
					the_DOC,"pkey_id",the_attr.gettype()));
			if(the_attr.gettype().equals("protein_id")){
				prefix = "SP:";
			}
		}
		if(the_attr.getvalue()!=null){
			Element pval = (Element)the_DOC.createElement("pval");
			String tmp = the_attr.getvalue();
			if(the_attr.getdate()!=null){
				tmp += "::DATE:"+the_attr.getdate();
			}
			if(the_attr.gettimestamp()!=null){
				tmp += "::TS:"+the_attr.gettimestamp();
			}
			if((prefix!=null)&&(!(tmp.startsWith(prefix)))){
				tmp = prefix+tmp;
			}
			pval.appendChild(the_DOC.createTextNode(tmp));
			atNode.appendChild(pval);
		}
		return atNode;
	}

	public Element makeDbxrefIdAttrNode(Document the_DOC,Attrib the_attr){
		Element atNode = (Element)the_DOC.createElement("dbxref_id");
		Element dbxrefNode = (Element)the_DOC.createElement("dbxref");
		if(the_attr.getxref_db()!=null){
			dbxrefNode.appendChild(makeGenericNode(
					the_DOC,"dbname",
					the_attr.getxref_db()));
			//Element dbname = (Element)the_DOC.createElement("dbname");
			//dbname.appendChild(the_DOC.createTextNode(the_attr.getxref_db()));
			//dbxrefNode.appendChild(dbname);
		}
		if(the_attr.getdb_xref_id()!=null){
			dbxrefNode.appendChild(makeGenericNode(
					the_DOC,"accession",
					the_attr.getdb_xref_id()));
			//Element accession = (Element)the_DOC.createElement("accession");
			//accession.appendChild(the_DOC.createTextNode(the_attr.getdb_xref_id()));
			//dbxrefNode.appendChild(accession);
		}
		atNode.appendChild(dbxrefNode);
		return atNode;
	}

	public Element makeFeatureDbxrefAttrNode(Document the_DOC,Attrib the_attr){
		Element attributeNode = (Element)the_DOC.createElement("feature_dbxref");
		attributeNode.appendChild(makeDbxrefIdAttrNode(the_DOC,the_attr));
		return attributeNode;
	}

	public Element makeCommentAttrNode(Document the_DOC,Attrib the_attr){
		Element attributeNode = (Element)the_DOC.createElement("featureprop");
		Element pkey_id = (Element)the_DOC.createElement("pkey_id");
		pkey_id.appendChild(the_DOC.createTextNode("comment"));
		attributeNode.appendChild(pkey_id);
		if(the_attr.gettext()!=null){
			Element pval = (Element)the_DOC.createElement("pval");
			String tmp = the_attr.gettext();
			if(the_attr.getdate()!=null){
				tmp += "::DATE:"+the_attr.getdate();
			}
			if(the_attr.gettimestamp()!=null){
				tmp += "::TS:"+the_attr.gettimestamp();
			}
			pval.appendChild(the_DOC.createTextNode(tmp));
			attributeNode.appendChild(pval);
		}
		if(the_attr.getperson()!=null){
			Element featureprop_pub = (Element)the_DOC.createElement("featureprop_pub");
			featureprop_pub.appendChild(makeGenericNode(
					the_DOC,"pub_id",
					the_attr.getperson()));
			attributeNode.appendChild(featureprop_pub);
		}
		return attributeNode;
	}

	public Element makeGameTempStorage(Document the_DOC,
			String the_pkey,String the_pval){
		Element atNode = (Element)the_DOC.createElement("featureprop");
		atNode.appendChild(makeGenericNode(the_DOC,"pkey_id",the_pkey));
		atNode.appendChild(makeGenericNode(the_DOC,"pval",the_pval));
		return atNode;
	}

	public Element makeFeatureLoc(Document the_DOC,Span the_span){
		Element featloc = (Element)the_DOC.createElement("featureloc");
		Element srcfeat = (Element)the_DOC.createElement("srcfeature_id");

		//SPAN
		//ONLY ADJUST A SPAN TO NEW COORDINATES IF IT IS WITH RESPECT
		//TO THE REF_SPAN, OTHER AltSpan()s FROM <result_span> SHOULD
		//NOT BE ADJUSTED
		//System.out.println("REFSTRING<"+m_NewREFSTRING
		//		+"> SRC<"+the_span.getSrc()+">");
		String refStr = null;
		Span tmp_span = the_span;
		if((m_OldREFSTRING!=null)&&(the_span.getSrc()!=null)
				&&(the_span.getSrc().equals(m_OldREFSTRING))){
			tmp_span = the_span.advance(m_REFSPAN.getStart());
			refStr = m_NewREFSTRING;
			//System.out.println("\tADVANCING BY<"
			//		+m_REFSPAN.toString()+">");
		}else{
			refStr = the_span.getSrc();
			//System.out.println("\tNOT ADVANCING");
		}
		if(refStr!=null){
			srcfeat.appendChild(the_DOC.createTextNode(refStr));
			featloc.appendChild(srcfeat);
		}

		//NBEG
		Element nbeg = (Element)the_DOC.createElement("nbeg");
		nbeg.appendChild(the_DOC.createTextNode((""+tmp_span.getStart())));
		featloc.appendChild(nbeg);

		//NEND
		Element nend = (Element)the_DOC.createElement("nend");
		nend.appendChild(the_DOC.createTextNode((""+tmp_span.getEnd())));
		featloc.appendChild(nend);

		//STRAND
		Element strand = (Element)the_DOC.createElement("strand");
		if(tmp_span.isForward()){
			strand.appendChild(the_DOC.createTextNode("+1"));
		}else{
			strand.appendChild(the_DOC.createTextNode("-1"));
		}
		featloc.appendChild(strand);
		return featloc;
	}

//COMPUTATIONAL_ANALYSIS
	public Element makeAnalFeat(Document the_DOC,GenFeat the_gf){
		Element feature = (Element)the_DOC.createElement("feature");
		if(the_gf.getId()==null){
			System.out.println("THIS ID IS REALLY NULL!!!!!!!!!!");
		}
		feature.setAttribute("id",the_gf.getId());
		//NAME
		//System.out.println("FEAT ID<"+the_gf.getId()
		//		+"> NAME<"+the_gf.getName()+">");
		if(the_gf.getName()!=null){
			feature.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		//UNIQUENAME
		String uniquename = the_gf.getId();
		if(uniquename==null){
			uniquename = "UNKNOWN";
		}
		feature.appendChild(makeGenericNode(
				the_DOC,"uniquename",uniquename));

		//ORGANISM_ID
		feature.appendChild(makeGenericNode(the_DOC,"organism_id","Dmel"));


		//CYCLE THROUGH THE RESULT SPANS TO GET A TYPE FOR THE RESULT_SET
		String rsft = null;
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			if(gf.getType()!=null){
				rsft = gf.getType();
				break;
			}
		}
		if(rsft!=null){
			//TYPE_ID
			Element typeId = (Element)the_DOC.createElement("type_id");
			if((the_gf.getType()==null)||(the_gf.getType().length()<=1)){
				typeId.appendChild(the_DOC.createTextNode(rsft));
			//}else{
			//	typeId.appendChild(the_DOC.createTextNode(""));
			}
			feature.appendChild(typeId);
		}else{
		}
		//RESULT_SPAN
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			feature.appendChild(makeAnalFeatRel(the_DOC,"contains",
					makeAnalFeatBodyNode(the_DOC,gf)));
		}
		return feature;
	}

	public Element makeAnalFeatRel(Document the_DOC,
			String the_relType,Element the_el){
		Element featrel = (Element)the_DOC.createElement("feature_relationship");
		//REL TYPE_ID
		featrel.appendChild(makeGenericNode(the_DOC,"type_id",the_relType));
		//REL SUBJ_FEATURE
		Element subjfeat = (Element)the_DOC.createElement("subjfeature_id");
		subjfeat.appendChild(the_el);
		featrel.appendChild(subjfeat);
		return featrel;
	}

	public Element makeAnalFeatBodyNode(Document the_DOC,GenFeat the_gf){
		//RESULT_SPAN
		Element feature = (Element)the_DOC.createElement("feature");
		if(the_gf.getId()==null){
			System.out.println("AND NOR SHOUL BE NULLEITHER!!!!!!!!");
		}
		feature.setAttribute("id",the_gf.getId());

		//UNIQUENAME
		String uniquename = the_gf.getId();
		if(uniquename==null){
			uniquename = "UNKNOWN";
		}
		feature.appendChild(makeGenericNode(
				the_DOC,"uniquename",uniquename));

		//ORGANISM_ID
		feature.appendChild(makeGenericNode(
				the_DOC,"organism_id","Dmel"));

		//TYPE_ID
		Element typeId = (Element)the_DOC.createElement("type_id");
		if(the_gf.getType()!=null){
			typeId.appendChild(the_DOC.createTextNode(the_gf.getType()));
		}else{
			typeId.appendChild(the_DOC.createTextNode("EMPTY"));
		}
		feature.appendChild(typeId);

		//SCORE
		if(the_gf.getScore()!=null){
			Element analFeatNode = (Element)the_DOC.createElement("analysisfeature");
			analFeatNode.appendChild(makeGenericNode(
					the_DOC,"rawscore",the_gf.getScore()));

			feature.appendChild(analFeatNode);
		}

		//FEATURELOC
		if(the_gf.getSpan()!=null){
			feature.appendChild(makeFeatureLoc(the_DOC,the_gf.getSpan()));
		}
		if(the_gf.getAltSpan()!=null){
			feature.appendChild(makeFeatureLoc(the_DOC,the_gf.getAltSpan()));
		}
		return feature;
	}

	public void preprocessCVTerms(GenFeat the_TopNode){
		if((the_TopNode instanceof FeatureSet)||(the_TopNode instanceof FeatureSpan)){
			storeCV("contains","relationship type");
		}
		if((the_TopNode.getId()!=null)
				&&(the_TopNode.getName()!=null)
				&&(!(the_TopNode.getId().equals(the_TopNode.getName())))){
			storeCV("synonym","property type");
		}

		if(the_TopNode instanceof Seq){
			storeCV("produces","relationship type");
			if(the_TopNode.getDescription()!=null){
				storeCV("description","property type");
			}
		}
		if(the_TopNode instanceof Aspect){
			storePUB("Gadfly","curated genome annotation");
			if(((Aspect)the_TopNode).getFunction()!=null){
				//storeCV("function","molecular_function");
				storeCVOnly("molecular_function");
			}
			if(((Aspect)the_TopNode).getComponent()!=null){
				storeCV("component","cellular_component");
				storeCVOnly("cellular_component");
			}
			if(((Aspect)the_TopNode).getProcess()!=null){
				storeCV("process","biological_process");
				storeCVOnly("biological_process");
			}
		}
		if(the_TopNode.getType()!=null){
			storeCV(the_TopNode.getType(),"feature type");
		}else if((the_TopNode.getId()!=null)
				&&(the_TopNode.getId().indexOf("-R")>0)){
			storeCV("mRNA","feature type");
		}else if((the_TopNode.getId()!=null)
				&&(the_TopNode.getId().indexOf("-P")>0)){
			storeCV("protein","feature type");
		}
		for(int i=0;i<the_TopNode.getAttribCount();i++){
			Attrib attr = the_TopNode.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType()!=null){
					if(attr.getAttribType().equals("comment")){
						storeCV(attr.getAttribType(),"property type");
					}
				}
				if(attr.gettype()!=null){
					storeCV(attr.gettype(),"property type");
				}
				if(attr.getperson()!=null){
					storePUB(attr.getperson(),"curated genome annotation");
				}
			}
		}
		//NONSTANDARD
		//AUTHOR
		if(the_TopNode.getAuthor()!=null){
			//System.out.println("===========AUTHOR PROPERTY ADDED");
			storeCV("author","property type");
			storePUB(the_TopNode.getAuthor(),"curated genome annotation");
		}
		storePUB("GadFly","curated genome annotation");

		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			preprocessCVTerms(gf);
		}
	}

	public Element makePreamble(Document the_DOC,Element the_Elem){
		if(m_CVList!=null){
			Iterator it = m_CVList.iterator();
			while(it.hasNext()){
				String txt = (String)it.next();
				//System.out.println("CV ITEM<"+txt+">");
				the_Elem.appendChild(createCV(the_DOC,txt));
			}
		}
		if(m_CVTERMList!=null){
			Iterator it1 = m_CVTERMList.iterator();
			while(it1.hasNext()){
				String txt = (String)it1.next();
				//System.out.println("CVTERM ITEM<"+txt+">");
				int indx = 0;
				if((indx = txt.indexOf("|"))>0){
					String txt1 = txt.substring(0,indx);
					String txt2 = txt.substring(indx+1);
					the_Elem.appendChild(createCVTERM(the_DOC,txt1,txt2));
				}
			}
		}
		//PUBLICATIONS
		if(m_PUBList!=null){
			Iterator it2 = m_PUBList.iterator();
			while(it2.hasNext()){
				String txt = (String)it2.next();
				//System.out.println("PUB ITEM<"+txt+">");
				the_Elem.appendChild(createPUB(the_DOC,txt));
			}
		}
		//ORGANISM
		the_Elem.appendChild(createORGANISM(the_DOC));
		return the_Elem;
	}

	public void storeCVOnly(String the_cvTxt){
		if(m_CVList==null){
			m_CVList = new HashSet();
		}
		m_CVList.add(the_cvTxt);
	}

	public void storeCV(String the_cvTxt,String the_cvtermTxt){
		if(m_CVList==null){
			m_CVList = new HashSet();
		}
		if(m_CVTERMList==null){
			m_CVTERMList = new HashSet();
		}

		m_CVList.add(the_cvtermTxt);
		m_CVTERMList.add(the_cvTxt+"|"+the_cvtermTxt);
	}

	public Element createCV(Document the_DOC,String txt){
		Element cv = (Element)the_DOC.createElement("cv");
		cv.setAttribute("op","lookup");
		cv.setAttribute("id",txt);
		Element cvname = (Element)the_DOC.createElement("cvname");
		cvname.appendChild(the_DOC.createTextNode(txt));
		cv.appendChild(cvname);
		return cv;
	}

	public Element createCVTERM(Document the_DOC,String txt,String txt1){
		Element cvterm = (Element)the_DOC.createElement("cvterm");
		cvterm.setAttribute("op","lookup");
		cvterm.setAttribute("id",txt);
		Element cv_id = (Element)the_DOC.createElement("cv_id");
		cv_id.appendChild(the_DOC.createTextNode(txt1));
		cvterm.appendChild(cv_id);
		Element termnameNode = (Element)the_DOC.createElement("name");
		termnameNode.appendChild(the_DOC.createTextNode(txt));
		cvterm.appendChild(termnameNode);
		return cvterm;
        }

        public void storePUB(String the_curatorTxt,String the_noteTxt){
		storeCV(the_noteTxt,"pub type");
                if(m_PUBList==null){
                        m_PUBList = new HashSet();
                }
                m_PUBList.add(the_curatorTxt);
        }

	public Element createPUB(Document the_DOC,String the_txt){
		Element pub = (Element)the_DOC.createElement("pub");
		pub.setAttribute("op","lookup");
		pub.setAttribute("id",the_txt);
		Element miniref = (Element)the_DOC.createElement("miniref");
		miniref.appendChild(the_DOC.createTextNode(the_txt+" curated genome annotation"));
		pub.appendChild(miniref);
		Element type_id = (Element)the_DOC.createElement("type_id");
		type_id.appendChild(the_DOC.createTextNode("curated genome annotation"));
		pub.appendChild(type_id);
		return pub;
	}

	public Element createORGANISM(Document the_DOC){
		Element organism = (Element)the_DOC.createElement("organism");
		organism.setAttribute("id","Dmel");
		Element genus = (Element)the_DOC.createElement("genus");
		genus.appendChild(the_DOC.createTextNode("Drosophila"));
		organism.appendChild(genus);
		Element species = (Element)the_DOC.createElement("species");
		species.appendChild(the_DOC.createTextNode("melanogaster"));
		organism.appendChild(species);
		//Element taxgroup = (Element)the_DOC.createElement("taxgroup");
		//taxgroup.appendChild(the_DOC.createTextNode("Arthopoda"));
		//organism.appendChild(taxgroup);
		return organism;
	}

	public String cleanString(String the_seq){
		StringBuffer sbuf = new StringBuffer();
                if(the_seq!=null){
                        int miscChar = 0;
                        int len = the_seq.length();
                        byte[] b = the_seq.getBytes();
			char[] c = the_seq.toCharArray();
                        for(int i=0;i<len;i++){
                                if((b[i]=='\n')||(b[i]==32)){
                                        miscChar++;
                                }else{
					sbuf.append(c[i]);
				}
                        }
                }
                return sbuf.toString();
        }
}


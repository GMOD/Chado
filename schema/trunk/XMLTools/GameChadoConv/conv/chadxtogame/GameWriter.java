//GameWriter.java
package conv.chadxtogame;

import java.io.*;
//import conv.util.*;

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

public class GameWriter {

private String m_InFile = null;
private String m_OutFile = null;
private Span m_NewREFSPAN = null;
private String m_NewREFSTRING = null;
private String m_OldREFSTRING = null;

//FOR BUILDING PREAMBLE
private HashSet m_CVList;
private HashSet m_CVTERMList;
private HashSet m_PUBList;
private HashSet m_EXONList;

private String m_ARMNAME = null;

String ANNORES_OFFSET = "\n      ";
String ANNORES_OFFSET_END = "\n    ";
String GAMERES_OFFSET = "\n          ";
String GAMERES_OFFSET_END = "\n        ";

//BECAUSE ANALYSIS FEATURES MAY BE EMBEDDED
//THEY NEED TO BE COLLECTED ALONG THE WAY AND
//PRINTED OUT IN THE END
private Vector m_AnalysisList = null;
//private boolean m_geneOnly = false;

public static int CONVERT_ALL = 0;
public static int CONVERT_GENE = 1;
public static int CONVERT_COMP = 2;
private int m_readMode = 0;

	public GameWriter(String the_infile,String the_outfile,
			int the_DistStart,int the_DistEnd,
			//String the_NewREFSTRING,boolean the_geneOnly){
			String the_NewREFSTRING,int the_readMode){
		if(the_infile==null){
			System.exit(0);
		}
		m_InFile = the_infile;
		m_OutFile = the_outfile;
		m_NewREFSPAN = new Span(the_DistStart,the_DistEnd);
		m_NewREFSTRING = the_NewREFSTRING;
		//m_geneOnly = the_geneOnly;
		m_readMode = the_readMode;
		if(m_OutFile!=null){
			System.out.println("START C->G INFILE<"+m_InFile
					+"> OUTFILE<"+m_OutFile
					+"> DIST<"+m_NewREFSPAN.toString()
					+"> NewREFSTRING<"+m_NewREFSTRING+">");
		}
		m_AnalysisList = new Vector();
	}

	public void ChadoToGame(){
		//PARSE CHADO FILE
		ChadoSaxReader csr = new ChadoSaxReader();
		csr.parse(m_InFile,m_readMode);
		GenFeat TopNode = csr.getTopNode();
		System.out.println("=============DONE READING FILE - WRITE GAME FILE\n");
		writeFile(TopNode,m_OutFile);
		if(m_OutFile!=null){
			System.out.println("DONE C->G INFILE<"+m_InFile
					+"> OUTFILE<"+m_OutFile+">\n");
		}
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
			Document m_DOC = impl.createDocument(null,"game",null);
			Element root = makeGameDoc(m_DOC,gf);

			DOMSource domSource = new DOMSource(m_DOC);
			StreamResult streamResult = null;
			if(the_filePathName!=null){
				streamResult = new StreamResult(
						new FileWriter(the_filePathName));
			}else{
				streamResult = new StreamResult(System.out);
			}
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
			m_DOC.appendChild(makeGameDoc(m_DOC,gf));
			Writer out = new OutputStreamWriter(new FileOutputStream(the_filePathName,false));
			m_DOC.write(out);
			out.flush();
			**************/
		}catch(Exception ex){
			ex.printStackTrace();
		}
	}

	public Element makeGameDoc(Document the_DOC,GenFeat the_TopNode){
		Element root = the_DOC.getDocumentElement();

		System.out.println("START READING METADATA");
		//USE METADATA FROM _APPDATA
		String mdARM=null,mdTITLE=null;
		String mdMIN=null,mdMAX=null,mdRESIDUES=null;
		the_TopNode = the_TopNode;
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			FeatSub gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Appdata){
				//System.out.println("FOUND appdata<"
				//		+gf.getId()+">");
				if(gf.getId().equals("arm")){
					mdARM = ((Appdata)gf).getText();
					System.out.println("\tARM<"+mdARM+">");
				}else if(gf.getId().equals("title")){
					mdTITLE = ((Appdata)gf).getText();
					System.out.println("\tTITLE<"
						+mdTITLE+">");
				}else if(gf.getId().equals("fmin")){
					mdMIN = ((Appdata)gf).getText();
					System.out.println("\tMIN<"
						+mdMIN+">");
				}else if(gf.getId().equals("fmax")){
					mdMAX = ((Appdata)gf).getText();
					System.out.println("\tMAX<"
						+mdMAX+">");
				}else if(gf.getId().equals("residues")){
					mdRESIDUES = ((Appdata)gf).getText();
					System.out.println("\tRESIDUES LEN<"
						+mdRESIDUES.length()+">");
				}else{
				}
			}
		}
		System.out.println("DONE READING METADATA");


		//FIGURE OUT CORRESPONDENCE OF THE SCAFFOLD TO ITS ARM
		String annotSeqName = null;
		if(mdTITLE!=null){
			annotSeqName = mdTITLE;
			if((mdMIN!=null)&&(mdMAX!=null)){
				m_NewREFSPAN = new Span(mdMIN,mdMAX);
			}
			if(m_NewREFSTRING!=null){
				annotSeqName = m_NewREFSTRING;
			}
		}else{
			//ANNOT SEQUENCE GET INFO
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = the_TopNode.getGenFeat(i);
				if((gf.getTypeId()!=null)&&(gf.getTypeId().startsWith("annot_sequence"))){
					if(m_NewREFSTRING!=null){
						annotSeqName = m_NewREFSTRING;
					}else{
						annotSeqName = gf.getId();
					}
				}
			}
		}

		System.out.println("START WRITING METADATA RELATED FEATURES");
		root.appendChild(makeNonAnnotSeqFeatFromMetadata(the_DOC,
				annotSeqName,mdRESIDUES,"true"));

		//MAP_POSITION
		if(mdARM!=null){
			System.out.println("\tFOUND ARM STRING<"+mdARM+">");
			root.appendChild(makeMapPos(the_DOC,
					annotSeqName,
					mdARM,
					new Span(mdMIN,mdMAX)));
			m_OldREFSTRING = annotSeqName;
		}else{
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = the_TopNode.getGenFeat(i);
				System.out.println("\tFEATSUB TYPE<"+gf.getTypeId()
						+"><"+gf.getId()+">");
				if((gf.getTypeId()!=null)
						&&(gf.getTypeId().startsWith("arm"))){
					System.out.println("MAP_POS FEATURE<"
							+gf.getTypeId()+">");
					m_ARMNAME = ((GenFeat)gf).getUniqueName();
					root.appendChild(makeMapPos(the_DOC,
							annotSeqName,
							m_ARMNAME,
							m_NewREFSPAN));
					m_OldREFSTRING = gf.getId();
				}
			}
		}
		System.out.println("DONE WRITING METADATA RELATED FEATURES");

		if((m_readMode==CONVERT_ALL)||(m_readMode==CONVERT_GENE)){
			System.out.println("START WRITING ANNOT FEATURES");
			System.out.println("CURR ANNOT NAME<"+annotSeqName
					+"> OLD<"+m_OldREFSTRING
					+"> NEW<"+m_NewREFSTRING+">");
			//ANNOTATION, SEQUENCE FEATURES
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = (FeatSub)the_TopNode.getGenFeat(i);
				if(gf.getTypeId()==null){
					//MUST BE METADATA STFF
				}else if(gf.getTypeId().startsWith("gene")){
					root.appendChild(makeAnnotation(the_DOC,
							(Feature)gf));
				}else if(gf.getTypeId().startsWith("sequence")){
					root.appendChild(makeNonAnnotSeqFeat(the_DOC,
							(Feature)gf,"false"));
				}else{
					//System.out.println("\tNOT WRITTEN SINCE UNKNOWN TYPE<"+gf.getTypeId()+">");
				}
			}
			System.out.println("DONE WRITING ANNOTATION FEATURES");
		}
		System.out.println("--------------------------------");

		if((m_readMode==CONVERT_ALL)||(m_readMode==CONVERT_COMP)){
			System.out.println("START WRITING ANALYSIS FEATURE");
			//COMP_ANAL FEATURES
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = (FeatSub)the_TopNode.getGenFeat(i);
				if(gf.getisanalysis().equals("1")){
					//System.out.println("\tIS_ANALYSIS=1");
					System.out.println("ANALYSIS<"
						+((Feature)gf).getName()
						+"> TYPE<"
						+((Feature)gf).getTypeId()+">");
					m_AnalysisList.add(makeCompAnalysis(
							the_DOC,(Feature)gf));
				}else{
					//System.out.println("\tIS_ANALYSIS=0");
					//gf.Display(1);
				}
			}
		}

		for(int i=0;i<m_AnalysisList.size();i++){
			System.out.println("\tWRITE ANALFEAT<"+i+">");
			Element el = (Element)m_AnalysisList.get(i);
			root.appendChild(el);
		}
		System.out.println("DONE WRITING ANALYSIS FEATURES");

		System.out.println("START WRITING CHANGED/DELETED FEATURES");
		//DELETE FEATURES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			FeatSub gf = the_TopNode.getGenFeat(i);
			if((gf.getTypeId()!=null)
				&&((gf.getTypeId().startsWith("deleted_"))
				||(gf.getTypeId().startsWith("changed_")))){
					System.out.println("WRITING CHANGE/DELETE FEATURE <"+gf.getId()+"> OF TYPE<"+gf.getTypeId()+">");
					root.appendChild(
						makeModFeat(the_DOC,(GenFeat)gf));
			}
		}
	/*************/
		System.out.println("DONE WRITING CHANGED/DELETED FEATURES");
		//System.out.println("VIEW MAPPING");
		//Mapping.Display();
		//System.out.println("DONE VIEWING MAPPING");
		return root;
	}

	public Element makeModFeat(Document the_DOC,GenFeat the_gf){
		//DEPENDS ON TYPE BEING CHECKED ABOVE
		Element modfeatNode = (Element)the_DOC.createElement(
				the_gf.getTypeId());
		String idStr = the_gf.getId();
		if(idStr!=null){
			//idStr = deNullString(idStr);
			modfeatNode.setAttribute("id",idStr);
		}
		return modfeatNode;
	}

	public Element makeNonAnnotSeqFeatFromMetadata(Document the_DOC,
			String the_name,
			String the_residues,String the_focus){
		Element seqNode = (Element)the_DOC.createElement("seq");
		if(the_name!=null){
			seqNode.setAttribute("id",the_name);
		}
		if(the_residues!=null){
			seqNode.setAttribute("length",
					""+countLength(the_residues));
		}
		if((the_focus!=null)&&(the_focus.equals("true"))){
			seqNode.setAttribute("focus",the_focus);
		}
		if(the_name!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"name",the_name));
		}
		if(the_residues!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"residues",
					formatResidues(the_residues)));
		}
		return seqNode;
	}

	public Element makeNonAnnotSeqFeat(Document the_DOC,
			GenFeat the_gf,String the_focus){
		Feature featgf = (Feature)the_gf;
		Element seqNode = (Element)the_DOC.createElement("seq");
		seqNode.setAttribute("id",featgf.getId());
		seqNode.setAttribute("length",
				""+countLength(featgf.getResidues()));
		if(featgf.getMd5()!=null){
			seqNode.setAttribute("md5checksum",featgf.getMd5());
		}
		if((the_focus!=null)&&(the_focus.equals("true"))){
			seqNode.setAttribute("focus",the_focus);
		}
		if(featgf.getName()!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"name",featgf.getName()));
		}

		for(int i=0;i<featgf.getFeatSubCount();i++){
			FeatSub fs = featgf.getFeatSub(i);
			if(fs!=null){
				if(fs instanceof FeatProp){
					FeatProp fp = (FeatProp)fs;
					String pkey = fp.getPkeyId();
					if(pkey!=null){
						if(pkey.equals("description")){
							//Attrib TO HOLD GAME
							//<description>
							String pval = fp.getpval();
							seqNode.appendChild(
								makeGameTempStorage(
								the_DOC,pkey,pval));
						}
					}
				}
			}
		}

		if(featgf.getResidues()!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"residues",
					formatResidues(featgf.getResidues())));
		}
		return seqNode;
	}

	public String formatResidues(String the_res){
		if(the_res==null){
			return null;
		}
		//return the_res;
		/***************/
		StringBuffer sb = new StringBuffer();
		while((the_res!=null)&&(the_res.length()>50)){
			sb.append("\n        "+the_res.substring(0,50));
			the_res = the_res.substring(51);
		}
		if(the_res!=null){
			sb.append("\n        "+the_res);
		}
		return sb.toString();
		/***************/
	}

	public Element makeFeatSubNode(Document the_DOC,FeatSub the_attr){
		System.out.println("FEATSUB ID <"+the_attr.getId()+">");
		if(the_attr instanceof FeatProp){
			System.out.println("\tFeatProp");
		}else if(the_attr instanceof FeatDbxref){
			System.out.println("\tFeatDbxref");
		}else{
			System.out.println("\tUNKNOWN");
		}
		return null;
	}


	public Element makeMapPos(Document the_DOC,
			String the_annotSeqName,
			String the_ARMname,
			Span the_span){
		Element mapPosNode = (Element)the_DOC.createElement("map_position");
		mapPosNode.setAttribute("type","tile");
		if(the_annotSeqName!=null){
			mapPosNode.setAttribute("seq",the_annotSeqName);
		}

		//ARM
		mapPosNode.appendChild(makeGenericNode(
					the_DOC,"arm",the_ARMname));

		if(the_span!=null){
			mapPosNode.appendChild(makeGameSpan(
					the_DOC,the_span,1));
		}
		return mapPosNode;
	}

	public Element makeAnnotation(Document the_DOC,Feature the_gf){
		//System.out.println("START ANNOTATION <"+the_gf.getId()
		//		+"> TYPE<"+the_gf.getTypeId()
		//		+"> SIZE<"+the_gf.getGenFeatCount()+">");
		Element annotNode = (Element)the_DOC.createElement(
				"annotation");
		if(the_gf.getUniqueName()!=null){
			the_gf.setId(the_gf.getUniqueName());
		}

		if(the_gf.getId()!=null){
			annotNode.setAttribute("id",the_gf.getId());
		}

		//IS_PROBLEM
		for(int i=0;i<((Feature)the_gf).getFeatSubCount();i++){
			FeatSub fs = ((Feature)the_gf).getFeatSub(i);
			if((fs!=null)&&(fs instanceof FeatProp)){
				FeatProp fp = (FeatProp)fs;
				if(fp==null){
				}else if(fp.getPkeyId().equals("problem")){
					annotNode.setAttribute("problem",
							fp.getpval());
				}
			}
		}

		if(the_gf.getName()!=null){
			annotNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		if(the_gf.getTypeId()!=null){
			annotNode.appendChild(makeGenericNode(
					the_DOC,"type",the_gf.getTypeId()));
		}

		//AUTHOR,PROPERTIES,COMMENTS
		makeAuthPropComm(annotNode,the_DOC,the_gf,true);

		//FEATURE_SET
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			Feature FSgf = (Feature)the_gf.getGenFeat(i);
			//System.out.println("\tTRANSCR COMPID<"+FSgf.getId()
			//		+"> OF TYPE<"+FSgf.getTypeId()+">");

			if(FSgf.getTypeId().equals("chromosome_arm")){
			}else{
				annotNode.appendChild(
						makeFeatureSet(the_DOC,FSgf));
			}
		}

		//System.out.println("END ANNOTATION");
		return annotNode;
	}

	public Element makeFeatureSet(Document the_DOC,Feature the_gf){
		//System.out.println("\tSTART FEATURE_SET ID<"+the_gf.getId()
		//		+"> SIZE<"+the_gf.getGenFeatCount()+">");
		if(the_gf.getUniqueName()!=null){
			the_gf.setId(the_gf.getUniqueName());
		}

		Element featureSetNode = (Element)the_DOC.createElement("feature_set");
		//name,type,author,date,property
		featureSetNode.setAttribute("id",the_gf.getId());

		//IS_PROBLEM
		for(int i=0;i<((Feature)the_gf).getFeatSubCount();i++){
			FeatSub fs = ((Feature)the_gf).getFeatSub(i);
			if((fs!=null)&&(fs instanceof FeatProp)){
				FeatProp fp = (FeatProp)fs;
				if(fp==null){
				}else if(fp.getPkeyId().equals("problem")){
					featureSetNode.setAttribute("problem",
							fp.getpval());
				}
			}
		}

		//PRODUCED SEQ HAS SAME NAME
		String producesSeq = null;
		if(the_gf.getName()!=null){
			producesSeq = the_gf.getId()+"_seq";
			featureSetNode.setAttribute(
				"produces_seq",producesSeq);
		}
		if(producesSeq!=null){
			featureSetNode.setAttribute("produces_seq",producesSeq);
		}

		//NAME
		if(the_gf.getName()!=null){
			featureSetNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		//TYPE
		if(the_gf.getTypeId()!=null){
			featureSetNode.appendChild(makeGenericNode(
					the_DOC,"type",translateCVTERM(
					the_gf.getTypeId())));
		}

		//AUTHOR
		makeAuthPropComm(featureSetNode,the_DOC,the_gf,false);

		Vector exonList = new Vector();
		Vector protList = new Vector();

		//GEN_FEATs
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			Feature gf = (Feature)the_gf.getGenFeat(i);
			if((gf!=null)&&(gf.getTypeId()!=null)&&(gf.getFeatLoc()!=null)){
				if(gf.getTypeId().equals("exon")){
					exonList.add(gf);
				}else if(gf.getTypeId().equals("protein")){
					protList.add(gf);
				}
			}
		}

		//WRITE START_CODON
		for(int i=0;i<protList.size();i++){
			Feature gf = (Feature)protList.get(i);
			Feature ngf = new Feature(gf.getId());
			ngf.setName(gf.getName());
			ngf.setTypeId("start_codon");
			ngf.setFeatLoc(gf.getFeatLoc());
			if(gf.getFeatLoc()!=null){
				Span tmpSpan = ngf.getFeatLoc().getSpan();
				if(tmpSpan!=null){
					if(tmpSpan.isForward()){
						tmpSpan = new Span(
						tmpSpan.getStart(),
						tmpSpan.getStart()+2);
					}else{
						tmpSpan = new Span(
						tmpSpan.getStart(),
						tmpSpan.getStart()-2);
					}
					ngf.getFeatLoc().setSpan(tmpSpan);
				}
			}
			featureSetNode.appendChild(
				makeFeatureSpan(
				the_DOC,ngf));
		}

		//SORT EXONS
		for(int i=0;i<exonList.size();i++){
			GenFeat gfi = (GenFeat)exonList.get(i);
			for(int j=(i+1);j<exonList.size();j++){
				GenFeat gfj = (GenFeat)exonList.get(j);
				if((gfi.getFeatLoc().getSpan()!=null)
						&&(gfj.getFeatLoc().getSpan()!=null)){
					if(gfj.getFeatLoc().getSpan().precedes(gfi.getFeatLoc().getSpan())){
						gfj = (GenFeat)exonList.set(j,gfi);
						exonList.set(i,gfj);
						gfi = gfj;
					}
				}else{
					System.out.println("SHOULD NOT SEE NULL SPAN");
				}
			}
		}

		//WRITE EXONS
		for(int i=0;i<exonList.size();i++){
			Feature gf = (Feature)exonList.get(i);
			//System.out.println("\tCOMP FEAT<"
			//		+gf.getId()+"> OF TYPE<"
			//		+gf.getTypeId()+">");
			featureSetNode.appendChild(
					makeFeatureSpan(the_DOC,gf));
		}

		//WRITE CDNA SEQUENCE
		if(the_gf.getResidues()!=null){
			featureSetNode.appendChild(
					makeGameSeq(the_DOC,
					the_gf.getId(),
					the_gf.getId(),
					the_gf.getResidues(),
					the_gf.getTypeId(),
					the_gf.getMd5()));
		}

		//WRITE PROTEIN SEQUENCE
		for(int i=0;i<protList.size();i++){
			Feature gf = (Feature)protList.get(i);
			featureSetNode.appendChild(
					makeGameSeq(the_DOC,
							gf.getId(),
							gf.getId(),
							gf.getResidues(),
							gf.getTypeId(),
							gf.getMd5()));
		}
		//System.out.println("\tEND FEATURE_SET");
		return featureSetNode;
	}

	public Element makeFeatureSpan(Document the_DOC,Feature the_gf){
		//EXONS IN CHADO
		if(the_gf.getUniqueName()!=null){
			the_gf.setId(the_gf.getUniqueName());
		}
		String featSpanName = the_gf.getName();

		Element featureSpanNode = (Element)
				the_DOC.createElement("feature_span");

//YYYYY - NEED TO DIFFERENTIATE BETWEEN A SEQUENCE INSIDE A FEATURE_SET 
//AND A REGULAR FEATURE_SPAN (exon)
		//name,type,seq_relationship,span
		//System.out.println("\t\tWRITING FEATURESPAN<"
		//		+the_gf.getId()+">");
		if(the_gf.getId()!=null){
			featureSpanNode.setAttribute("id",the_gf.getId());
			//PRODUCED SEQ HAS SAME NAME
			if((the_gf.getTypeId()!=null)
					&&(the_gf.getTypeId().equals("protein"))){
				featureSpanNode.setAttribute(
						"produces_seq",
						the_gf.getId()+"_seq");
				featSpanName = the_gf.getId();
			}
		}

		if(featSpanName!=null){
			featureSpanNode.appendChild(makeGenericNode(
					the_DOC,"name",featSpanName));
		}
		if(the_gf.getTypeId()!=null){
			featureSpanNode.appendChild(makeGenericNode(
					the_DOC,"type",
					translateCVTERM(the_gf.getTypeId())));
		}
		if((the_gf.getFeatLoc()!=null)
				&&(the_gf.getFeatLoc().getSpan()!=null)){
			Span sp = the_gf.getFeatLoc().getSpan();
			Span spRet = sp.retreat((m_NewREFSPAN.getStart()-1));
			//INTERBASE COMPENSATION
			spRet = new Span(spRet.getStart()+1,spRet.getEnd());
			//System.out.println("RETREATING ID<"+the_gf.getId()
			//		+">\tSP<"+sp+">\tTO<"+spRet+">");

			int strand = the_gf.getFeatLoc().getstrand();
			the_gf.getFeatLoc().setSpan(spRet);
			featureSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_gf,spRet,strand,
					m_OldREFSTRING,"query",null));
		}
		return featureSpanNode;
	}

	public String translateCVTERM(String the_type){
		if(the_type==null){
			return "";
		}
		if(the_type.equals("mRNA")){
			return "transcript";
		}else if(the_type.equals("protein")){
			return "aa";
		}else if(the_type.equals("DNA_transposon")){
			return "transposon";
		}else{
			return the_type;
		}
	}

	public Element makeGameSeq(Document the_DOC,
			String the_Id,
			String the_Name,
			String the_Residues,
			String the_TypeId,
			String the_Md5){
		Element seqNode = (Element)the_DOC.createElement("seq");
		//ID
		if(the_Id!=null){
			seqNode.setAttribute("id",the_Id+"_seq");
		}
		//LENGTH
		seqNode.setAttribute("length",""+countLength(the_Residues));
		//TYPE
		if(the_TypeId!=null){
			if(the_TypeId.equals("transcript")){
				seqNode.setAttribute("type","cdna");
				//SINCE THIS SEQUENCE IS STORED AS A
				//RESIDUES OF A FEATURE
			}else if(the_TypeId.equals("mRNA")){
				//seqNode.setAttribute("type","aa");
				seqNode.setAttribute("type","cdna");
			}else if(the_TypeId.equals("protein")){
				seqNode.setAttribute("type","aa");
			}else{
				seqNode.setAttribute("type",
						translateCVTERM(the_TypeId));
			}
		}
		//MD5CHECKSUM
		if(the_Md5!=null){
			seqNode.setAttribute("md5checksum",the_Md5);
		}

		//NAME
		if(the_Id!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"name",the_Id+"_seq"));
		}

		//RESIDUES
		seqNode.appendChild(makeGenericNode(the_DOC,"residues",
				formatResidues(the_Residues)));
		return seqNode;
	}

	public int countLength(String the_seq){
		if(the_seq!=null){
			int miscChar = 0;
			int len = the_seq.length();
			byte[] b = the_seq.getBytes();
			for(int i=0;i<len;i++){
				if((b[i]=='\n')||(b[i]==32)){
					miscChar++;
				}
			}
			return (len-miscChar);
		}
		return 0;
	}

	public void makeAuthPropComm(
			Element the_Node,Document the_DOC,
			Feature the_gf,boolean the_isAnnotation){

		//  DATE
		if(the_gf.gettimeaccessioned()!=null){
			the_Node.appendChild(makeDateNode(
				the_DOC,the_gf.gettimeaccessioned()));
		}

		for(int i=0;i<((Feature)the_gf).getFeatSynCount();i++){
			FeatSyn fs = ((Feature)the_gf).getFeatSyn(i);
			//System.out.println("GAMEWRITER FEATSYN<"
			//		+fs.getSynonym().getname()
			//		+"> INTERNAL<"+fs.getisinternal()+">");
			if(fs.getisinternal().equals("1")){
				the_Node.appendChild(makeGameProperty(the_DOC,
						"internal_synonym",
						fs.getSynonym().getname()));
			}else{
				the_Node.appendChild(makeGenericNode(
						the_DOC,"synonym",
						fs.getSynonym().getname()));
			}
		}

		//  AUTHOR,PROPERTIES,COMMENTS
		Vector propList = new Vector();
		Vector commentList = new Vector();
		Vector authorList = new Vector();
		for(int i=0;i<((Feature)the_gf).getFeatSubCount();i++){
			FeatSub fs = ((Feature)the_gf).getFeatSub(i);
			if((fs!=null)&&(fs instanceof FeatProp)){
				FeatProp fp = (FeatProp)fs;
				//System.out.print(" KEY<"+fp.getPkeyId()
				//		+"> VAL<"+fp.getpval()+">");
				if(fp==null){
				}else if(fp.getPkeyId()==null){
					//DO NOTHING
				}else if(fp.getPkeyId().equals("comment")){
					commentList.add(
						makeGameFeatPropComment(
							the_DOC,fp));
				}else if(fp.getPkeyId().equals("author")){
					authorList.add(
						makeGenericNode(the_DOC,
							"author",fp.getpval()));
				//}else if(fp.getPkeyId().equals("problem")){
				}else{
					propList.add(
						makeGameFeatPropReg(the_DOC,fp));
				}
			}
		}

		//  AUTHOR
		for(int i=0;i<authorList.size();i++){
			Element el = (Element)authorList.get(i);
			the_Node.appendChild(el);
		}

		//  PROPERTIES
		for(int i=0;i<propList.size();i++){
			Element el = (Element)propList.get(i);
			the_Node.appendChild(el);
		}

		if((the_gf.getTypeId()!=null)
				&&(the_gf.getTypeId().equals("gene"))){
			if(the_gf.getName()!=null){
				Element geneNode = (Element)the_DOC
						.createElement("gene");
				geneNode.setAttribute("id",the_gf.getName());
				geneNode.setAttribute("association","IS");
				geneNode.appendChild(makeGenericNode(the_DOC,
						"name",the_gf.getName()));
				the_Node.appendChild(geneNode);
			}
		}

		//  COMMENTS
		for(int i=0;i<commentList.size();i++){
			Element el = (Element)commentList.get(i);
			the_Node.appendChild(el);
		}

		if(the_isAnnotation){
				//THEN PROVIDE DBXREF, ELSE DONT
		//  DBXREF
		String tmpdbname = "";
		if(((Feature)the_gf).getDbxrefId()!=null){
			Dbxref d = ((Feature)the_gf).getDbxref();
			tmpdbname = d.getDBId();
			if((tmpdbname!=null)&&(d.getaccession()!=null)){
				the_Node.appendChild(makeGameDbxref(the_DOC,
						tmpdbname,
						d.getaccession()));
			}
		}

		for(int i=0;i<((Feature)the_gf).getFeatDbxrefCount();i++){
			FeatDbxref fd = (FeatDbxref)((Feature)the_gf)
					.getFeatDbxref(i);
			Dbxref d = fd.getDbxref();
			String tmpdbname2 = d.getDBId();
			if((d!=null)&&(!(tmpdbname2.equals(tmpdbname)))){
				if((tmpdbname2!=null)&&(d.getaccession()!=null)){
					the_Node.appendChild(
							makeGameDbxref(the_DOC,
							tmpdbname2,
							d.getaccession()));
				}
			}
		}
		}
	}

	public Element makeGenericNode(Document the_DOC,
			String the_type,String the_text){
		Element genericNode = (Element)the_DOC.createElement(the_type);
		genericNode.appendChild(the_DOC.createTextNode(the_text));
		return genericNode;
	}

	public Element makeGameTempStorage(Document the_DOC,
			String the_pkey,String the_pval){
		//FOR GAME NonAnnot 'seq' length when no <residues>
		Element descNode = (Element)the_DOC.createElement(the_pkey);
		descNode.appendChild(the_DOC.createTextNode(
				"\n  "+the_pval+"\n    "));
		return descNode;
	}

	public Element makeGameDbxref(Document the_DOC,
			String the_xref_dbTxt,String the_db_xref_idTxt){
		Element attrNode = (Element)the_DOC.createElement("dbxref");
		if(the_xref_dbTxt!=null){
			Element xref_dbNode = (Element)the_DOC.createElement("xref_db");
			xref_dbNode.appendChild(the_DOC.createTextNode(the_xref_dbTxt));
			attrNode.appendChild(xref_dbNode);
		}
		if(the_db_xref_idTxt!=null){
			Element db_xref_idNode = (Element)the_DOC.createElement("db_xref_id");
			db_xref_idNode.appendChild(the_DOC.createTextNode(the_db_xref_idTxt));
			attrNode.appendChild(db_xref_idNode);
		}
		return attrNode;
	}

	public Element makeGameComment(Document the_DOC,
				String the_textTxt,
				String the_personTxt,
				String the_dateTxt,
				String the_timestampTxt){
		Element attrNode = (Element)the_DOC.createElement("comment");
		attrNode.setAttribute("internal","false");
		if(the_textTxt!=null){
			Element textNode = (Element)the_DOC.createElement("text");
			textNode.appendChild(the_DOC.createTextNode(
					"\n"+the_textTxt+"\n      "));
			attrNode.appendChild(textNode);
		}
		if(the_personTxt!=null){
			Element personNode = (Element)the_DOC.createElement("person");
			personNode.appendChild(the_DOC.createTextNode(the_personTxt));
			attrNode.appendChild(personNode);
		}
		//IGNORE TIMESTAMP AS IT CAN BE REGENERATED
		if(the_dateTxt!=null){
			//DONT CONVERT IT, AS IS A LEGACY GAME DATE
			attrNode.appendChild(
				makeUnchangedDateNode(the_DOC,the_dateTxt));
		}
		return attrNode;
	}

	public Element makeUnchangedDateNode(Document the_DOC,
			String the_gamedate){
		Element dateNode = (Element)the_DOC.createElement("date");
		//String gametimestamp = DateConv.GameDateToTimestamp(
		//		the_gamedate);
		//System.out.println("UNCHANGED GAME<"+gametimestamp+">");
		//if(gametimestamp!=null){
		//	dateNode.setAttribute("timestamp",gametimestamp);
		//}
		String chadotimestamp = DateConv.ChadoDateToTimestamp(
				the_gamedate);
		//System.out.println("UNCHANGED CHADO<"+chadotimestamp+">");
		if(chadotimestamp!=null){
			dateNode.setAttribute("timestamp",chadotimestamp);
		}
		//if(the_gamedate!=null){
		//	dateNode.appendChild(the_DOC.createTextNode(
		//		the_gamedate));
		//}
		String chadoDate = DateConv.GameTimestampToChadoDate(
				chadotimestamp);
		if(chadoDate!=null){
			dateNode.appendChild(the_DOC.createTextNode(
				chadoDate));
		}
		return dateNode;
	}

	public Element makeDateNode(Document the_DOC,String the_chadodate){
		Element dateNode = (Element)the_DOC.createElement("date");
		String gametimestamp = DateConv.ChadoDateToTimestamp(
				the_chadodate);
		if(gametimestamp!=null){
			dateNode.setAttribute("timestamp",gametimestamp);
		}
		String gamedate = DateConv.ChadoDateToGameDate(the_chadodate);
		if(gamedate!=null){
			dateNode.appendChild(the_DOC.createTextNode(gamedate));
		}
		return dateNode;
	}

	public Element makeSeqRelNode(Document the_DOC,
			GenFeat the_gf,Span the_Span,int the_strand,
			String the_refName,String the_typeName,
			String the_Align){
		//System.out.println("MAKING SEQRELNODE");
		//BECAUSE SOMETIMES ITS THE 'ALT' SPAN
		//SO NEED TO ACTUALLY PASS IN THE SPAN
		Element seqRelNode = (Element)the_DOC.createElement(
				"seq_relationship");
		if(the_typeName!=null){
			seqRelNode.setAttribute("type",the_typeName);
		}else{
			seqRelNode.setAttribute("type","TYPE_UNKNOWN");
		}
		if(the_refName!=null){
			seqRelNode.setAttribute("seq",the_refName);
		}else{
			seqRelNode.setAttribute("seq","SEQ_UNKNOWN");
		}
		seqRelNode.appendChild(makeGameSpan(the_DOC,
				the_Span,the_strand));
		if(the_Align!=null){
			seqRelNode.appendChild(makeGenericNode(the_DOC,
					"alignment",the_Align));
		}
		return seqRelNode;
	}

	public Element makeCompAnalysis(Document the_DOC,Feature the_ca){
		//Each feature with is_analysis = 1 is a comp_anal feature.
		//It is either a match, transposable_element, or an exon?
		Element compAnalNode = (Element)the_DOC.createElement(
				"computational_analysis");

		String resSpanType = "";
		if(the_ca.getprogram()!=null){
			System.out.println("\tCOMP_ANAL PROGRAM<"+
					the_ca.getprogram()+">");
			compAnalNode.appendChild(makeGenericNode(the_DOC,
					"program",the_ca.getprogram()));
			resSpanType = the_ca.getprogram();
		}
		resSpanType += ":";

		if(the_ca.getsourcename()!=null){
			System.out.println("\tCOMP_ANAL SOURCENAME<"+
					the_ca.getsourcename()+">");
			compAnalNode.appendChild(makeGenericNode(the_DOC,
					"database",the_ca.getsourcename()));
			resSpanType += the_ca.getsourcename();
		}

		//if(the_ca.getprogramversion()!=null){
		//	System.out.println("\tCOMP_ANAL PROGRAMVERSION<"+
		//			the_ca.getprogramversion()+">");
		//	compAnalNode.appendChild(makeGenericNode(the_DOC,
		//			"version",the_ca.getprogramversion()));
		//}

		compAnalNode.appendChild(makeGameProperty(the_DOC,
				"qseq_type","genomic"));

		if(the_ca.getTypeId().equals("match")){
			System.out.println("+++++++++++++++MATCH");
			String prog = the_ca.getprogram();
			if(prog.startsWith("promotor")){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","Promotor Prediction"));
			}else if((prog.startsWith("genscan"))
					||(prog.startsWith("piecegenie"))){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","Gene Prediction"));
			}else{
				System.out.println("+++++++++++++++SOMENEWPROGRAM<"+prog+">");
			}
			if(the_ca.gettimeaccessioned()!=null){
				compAnalNode.appendChild(makeDateNode(the_DOC,
						the_ca.gettimeaccessioned()));
			}
			Element resultSetNode = makeResultSetForMatch(
					the_DOC,the_ca,resSpanType);
			compAnalNode.appendChild(resultSetNode);

		}else{// if(the_ca.getTypeId().equals("transposable_element")){
			System.out.println("+++++++++++++++TRANSPOSON");
			compAnalNode.appendChild(makeGameProperty(the_DOC,
					"type","Transposon"));
			if(the_ca.gettimeaccessioned()!=null){
				compAnalNode.appendChild(makeDateNode(the_DOC,
						the_ca.gettimeaccessioned()));
			}
			Element resultSetNode = makeResultSetForTransposon(
					the_DOC,the_ca,"transposon");
			compAnalNode.appendChild(resultSetNode);
		//}else{
		//	System.out.println("+++++++++++++++OTHER<"+the_ca.getTypeId()+">");
		}

		System.out.println("\n");
		return compAnalNode;
	}

	public Element makeResultSetForMatch(Document the_DOC,
			Feature the_ca,String the_resSpanType){
		Element resultSetNode = (Element)the_DOC.createElement(
				"result_set");

		//if(the_ca.getId()!=null){
		//	System.out.println("\tRESULT_SET ID<"
		//			+the_ca.getId()+">");
		//	resultSetNode.setAttribute("id",the_ca.getId());
		//}

		if(the_ca.getUniqueName()!=null){
			System.out.println("\tRESULT_SET UNIQUENAME<"
					+the_ca.getUniqueName()+">");
			resultSetNode.setAttribute("id",the_ca.getUniqueName());
		}

		if(the_ca.getName()!=null){
			System.out.println("\tRESULT_SET NAME<"
					+the_ca.getName()+">");
			resultSetNode.appendChild(makeGenericNode(the_DOC,
					"name",the_ca.getName()));
		}


		System.out.println("\tCOMP_ANAL SCORE <"
				+the_ca.getrawscore()+">");

		Vector rSpanList = new Vector();
		//BUILD SPAN LIST
		for(int i=0;i<the_ca.getGenFeatCount();i++){
			//EACH ONE OF THESE IS A RESULT_SPAN CORRESPONDING
			//TO A FEATURE_RELATIONSHIP IN CHADO
			GenFeat CAgf = (GenFeat)the_ca.getGenFeat(i);
			System.out.println("\t\tRESULT_SPAN ID<"+CAgf.getId()
					+"> TYPE<"+CAgf.getTypeId()+">:");
			System.out.println("\t\tRESULT_SPAN UN<"
					+CAgf.getUniqueName()+">");
			System.out.println("RESULT_SPAN TYPE SHOULD BE<"
					+the_resSpanType+">");
			if(CAgf.getFeatLoc()!=null){
				System.out.println("\t\t\tQUERY SEQ_REL<"
					+CAgf.getFeatLoc().getSpan()+">");
			}
			if(CAgf.getAltFeatLoc()!=null){
				System.out.println("\t\t\tSBJCT SEQ_REL<"
					+CAgf.getAltFeatLoc().getSpan()+">");
			}
			rSpanList.add(CAgf);
		}

		//SORT SPAN LIST
		for(int i=0;i<rSpanList.size();i++){
			Feature cai = (Feature)rSpanList.get(i);
			for(int j=(i+1);j<rSpanList.size();j++){
				Feature caj = (Feature)rSpanList.get(j);
				if((cai.getFeatLoc()!=null)
					&&(cai.getFeatLoc().getSpan()!=null)
					&&(caj.getFeatLoc()!=null)
					&&(caj.getFeatLoc().getSpan()!=null)){
					if(caj.getFeatLoc().getSpan().precedes(cai.getFeatLoc().getSpan())){
						caj = (Feature)rSpanList.set(j,cai);
						rSpanList.set(i,caj);
						cai = caj;
					}
				}else{
					System.out.println("SHOULD NOT SEE COMP_ANAL NULL SPAN");
				}
			}
		}

		//DISPLAY FOR TEST
		Span resultSetSpan = new Span(0,0);
		for(int i=0;i<rSpanList.size();i++){
			Feature ca = (Feature)rSpanList.get(i);
			if((ca!=null)&&(ca.getFeatLoc()!=null)){
				Span sp = ca.getFeatLoc().getSpan();
				String sfi = ca.getFeatLoc().getSrcFeatureId();
				System.out.println("SRC_FEAT FEATID<"+sfi+">");
				Feature tmp = (Feature)Mapping.Lookup(sfi);
				//INTERBASE CONVERSION
				sp = new Span(sp.getStart()+1,sp.getEnd());
				resultSetSpan.grow(sp);
				ca.getFeatLoc().setSpan(sp);
			}else{
				System.out.println("MISSING FEATLOC!!!");
			}
		}

		int strand = 1;

		//ONLY ADD A SEQ_REL WHEN THERE ARE MULTIPLE RESULT_SPANS
		//THE SEQ IS THE SAME AS THE QUERY STRING
		System.out.println("RESSPANSIZE<"+rSpanList.size()+">");
		if(rSpanList.size()>3){//INCLUDING DUMMY ONE WITH NO FEATLOC
			//GET QUERY NAME FROM QUERY RESULT_SPAN FOR RESULT_SET
//VERYVERYKLUDGY - FIX LATER
			String queryName = "";
			for(int i=0;i<rSpanList.size();i++){
				Feature ca = (Feature)rSpanList.get(i);
				if((ca!=null)&&(ca.getFeatLoc()!=null)){
				for(int j=0;j<ca.getGenFeatCount();j++){
					GenFeat gf = (GenFeat)ca.getGenFeat(j);
					if(j==1){
						queryName = gf.getUniqueName();
						break;
					}
				}
				}
			}
			resultSetNode.appendChild(makeSeqRelNode(
					the_DOC,the_ca,
					resultSetSpan,
					strand,queryName,"query",null));
		}

		//WRITE SPAN LIST
		for(int i=0;i<rSpanList.size();i++){
			Feature ca = (Feature)rSpanList.get(i);
			if((ca!=null)&&(ca.getFeatLoc()!=null)){
				Element caresSpan = makeNewResultSpan(
						the_DOC,ca,
						the_resSpanType,
						ca.getrawscore(),true);
				resultSetNode.appendChild(caresSpan);
			}
		}
		return resultSetNode;
	}

	public Element makeResultSetForTransposon(Document the_DOC,
			Feature the_ca,String the_resSpanType){
		Element resultSetNode = (Element)the_DOC.createElement(
				"result_set");

		if(the_ca.getId()!=null){
			System.out.println("\tTRANSP RESULT_SET ID<"
					+the_ca.getId()+">");
			resultSetNode.setAttribute("id",the_ca.getId());
		}

		if(the_ca.getName()!=null){
			System.out.println("\tTRANSP RESULT_SET NAME<"
					+the_ca.getName()+">");
			resultSetNode.appendChild(makeGenericNode(the_DOC,
					"name",the_ca.getName()));
		}
		System.out.println("\tTRANSP COMP_ANAL SCORE <"
				+the_ca.getrawscore()+">");

		Vector rSpanList = new Vector();
		//BUILD SPAN LIST
		for(int i=0;i<the_ca.getGenFeatCount();i++){
			//EACH ONE OF THESE IS A RESULT_SPAN CORRESPONDING
			//TO A FEATURE_RELATIONSHIP IN CHADO
			GenFeat CAgf = (GenFeat)the_ca.getGenFeat(i);
			System.out.println("\t\tTRANSP RESULT_SPAN ID<"+CAgf.getId()
					+"> TYPE<"+CAgf.getTypeId()+">:");
			System.out.println("\t\tTRANSP RESULT_SPAN UN<"
					+CAgf.getUniqueName()+">");
			System.out.println("TRANSP RESULT_SPAN TYPE SHOULD BE<"
					+the_resSpanType+">");
			if(CAgf.getFeatLoc()!=null){
				System.out.println("\t\t\tTRANSP QUERY SEQ_REL<"
					+CAgf.getFeatLoc().getSpan()+">");
			}
			if(CAgf.getAltFeatLoc()!=null){
				System.out.println("\t\t\tTRANSP SBJCT SEQ_REL<"
					+CAgf.getAltFeatLoc().getSpan()+">");
			}
			rSpanList.add(CAgf);
		}

		//SORT SPAN LIST
		for(int i=0;i<rSpanList.size();i++){
			Feature cai = (Feature)rSpanList.get(i);
			for(int j=(i+1);j<rSpanList.size();j++){
				Feature caj = (Feature)rSpanList.get(j);
				if((cai.getFeatLoc()!=null)
					&&(cai.getFeatLoc().getSpan()!=null)
					&&(caj.getFeatLoc()!=null)
					&&(caj.getFeatLoc().getSpan()!=null)){
					if(caj.getFeatLoc().getSpan().precedes(cai.getFeatLoc().getSpan())){
						caj = (Feature)rSpanList.set(j,cai);
						rSpanList.set(i,caj);
						cai = caj;
					}
				}else{
					System.out.println("SHOULD NOT SEE COMP_ANAL NULL SPAN");
				}
			}
		}

		//DISPLAY FOR TEST
		Span resultSetSpan = new Span(0,0);
		for(int i=0;i<rSpanList.size();i++){
			Feature ca = (Feature)rSpanList.get(i);
			if((ca!=null)&&(ca.getFeatLoc()!=null)){
				Span sp = ca.getFeatLoc().getSpan();
				String sfi = ca.getFeatLoc().getSrcFeatureId();
				System.out.println("SRC_FEAT FEATID<"+sfi+">");
				Feature tmp = (Feature)Mapping.Lookup(sfi);
				//INTERBASE CONVERSION
				sp = new Span(sp.getStart()+1,sp.getEnd());
				resultSetSpan.grow(sp);
				ca.getFeatLoc().setSpan(sp);
			}else{
				System.out.println("MISSING FEATLOC!!!");
			}
		}

		//WRITE SPAN LIST
		//FOR TRANSPOSONS, THE RAWSCORE IS STORED IN TOP <ANAL_FEAT>
		String rawscore = the_ca.getrawscore();
		for(int i=0;i<rSpanList.size();i++){
			Feature ca = (Feature)rSpanList.get(i);
			if((ca!=null)&&(ca.getFeatLoc()!=null)){
				Element caresSpan = makeNewResultSpan(
						the_DOC,ca,
						//ca.getTypeId(),
						the_resSpanType,
						rawscore,false);
				resultSetNode.appendChild(caresSpan);
			}
		}
		return resultSetNode;
	}

	public Element makeNewResultSpan(Document the_DOC,Feature the_ca,
			String the_typeId,String the_score,boolean m_isMatch){
		System.out.println("\tRESULT_SPAN TYPE<"+the_typeId+">");
		Element resultSpanNode = (Element)the_DOC.createElement("result_span");
		//if(the_ca.getId()!=null){
		//	resultSpanNode.setAttribute("id",the_ca.getId());
		//}
		if(the_ca.getUniqueName()!=null){
			String unm = the_ca.getUniqueName();
			//FFF
			//unm = deNullString(unm);
			//int indx = unm.indexOf(":");
			//if(indx>0){
			//	System.out.print("CHANGING <"+unm+"> TO<");
			//	unm = unm.substring(indx);
			//	System.out.println(unm+">");
			//}
			resultSpanNode.setAttribute("id",unm);
		}

		if(the_ca.getName()!=null){
			resultSpanNode.appendChild(makeGenericNode(
					the_DOC,"name",the_ca.getName()));
		}

		if(the_typeId!=null){
			String catypeId = convertCompAnalType(the_typeId);
			resultSpanNode.appendChild(makeGenericNode(
					the_DOC,"type",catypeId));
		}

		System.out.println("\tRESULT_SPAN SCORE <"+the_score+">");
		if(the_score!=null){
			resultSpanNode.appendChild(makeGenericNode(
					the_DOC,"score",the_score));
			Element outputNode = (Element)the_DOC.createElement(
					"output");
			outputNode.appendChild(makeGenericNode(
					the_DOC,"type","score"));
			outputNode.appendChild(makeGenericNode(
					the_DOC,"value",the_score));
			resultSpanNode.appendChild(outputNode);
		}

		String queryName = "";
		String queryResidues = "";
		String subjName = "";
		String subjResidues = "";
		for(int i=0;i<the_ca.getGenFeatCount();i++){
			GenFeat gf = (GenFeat)the_ca.getGenFeat(i);
			//System.out.println("GGGGF<"+gf.getName()+">");
			//System.out.println("GGGGFF<"+((Feature)gf).getResidues()+">");
			if(i==0){
				subjName = gf.getUniqueName();
				subjResidues = ((Feature)gf).getResidues();
			}else if(i==1){
				queryName = gf.getUniqueName();
				queryResidues = ((Feature)gf).getResidues();
			}
		}
		System.out.println("\tSUBJ NAME <"+subjName
				+"> RES<"+subjResidues+">");
		System.out.println("\tQUERY NAME <"+queryName
				+"> RES<"+queryResidues+">");

		//SUBJECT
		if(m_isMatch){
		if(the_ca.getAltFeatLoc()!=null){
			Span altsp = the_ca.getAltFeatLoc().getSpan();
			Span altspRet = altsp.retreat(m_NewREFSPAN.getStart()-1);
			//INTERBASE CONVERSION
			altspRet = new Span(altspRet.getStart()+1,altspRet.getEnd());
			int strand = the_ca.getAltFeatLoc().getstrand();
			//queryName = deNullString(queryName);
			resultSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_ca,altspRet,strand,
					queryName,"query",
					queryResidues));
		}
		
		if(the_ca.getFeatLoc()!=null){
			Span sp = the_ca.getFeatLoc().getSpan();
			//if(the_ca.getAltFeatLoc()!=null){
			//	strand = the_ca.getAltFeatLoc().getstrand();
			//}
			int strand = the_ca.getFeatLoc().getstrand();
			//subjName = deNullString(subjName);
			resultSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_ca,sp,strand,
					subjName,"subject",
					subjResidues));
		}
		}else{
			if(the_ca.getFeatLoc()!=null){
				Span sp = the_ca.getFeatLoc().getSpan();
				Span spRet = sp.retreat(m_NewREFSPAN.getStart()-1);
				//INTERBASE CONVERSION
				spRet = new Span(spRet.getStart()+1,spRet.getEnd());
				int strand = the_ca.getFeatLoc().getstrand();
				//subjName = deNullString(subjName);
				resultSpanNode.appendChild(makeSeqRelNode(
						the_DOC,the_ca,spRet,strand,
						subjName,"query",
						subjResidues));
			}
		}

		return resultSpanNode;
	}

	public String deNullString(String the_str){
		int indx = the_str.indexOf(":");
		if(indx>0){
			the_str = the_str.substring(indx+1);
		}
		return the_str;
	}

	public String convertCompAnalType(String the_typeId){
		String res = the_typeId;
		System.out.println("CONVERTING COMP_ANAL TYPE<"
				+the_typeId+"> TO<"+res+">");
		res = "alignment";
		return res;
	}

	public Element makeGameSpan(Document the_DOC,Span testSpan,int the_strand){
		Element gameSpanNode = (Element)the_DOC.createElement("span");
		//System.out.println("+++GAMESPAN STRAND<"+the_strand+">");
		if(the_strand==-1){
			gameSpanNode.appendChild(makeGenericNode(
				the_DOC,"start",(""+testSpan.getEnd())));
			gameSpanNode.appendChild(makeGenericNode(
				the_DOC,"end",(""+testSpan.getStart())));
		}else{
			gameSpanNode.appendChild(makeGenericNode(
				the_DOC,"start",(""+testSpan.getStart())));
			gameSpanNode.appendChild(makeGenericNode(
				the_DOC,"end",(""+testSpan.getEnd())));
		}
		return gameSpanNode;
	}

	public Element makeGameFeatPropReg(Document the_DOC,FeatProp the_fp){
		//System.out.println("FEATPROP makeGameFeatPropReg()!!!");
		String pkeyIdTxt = the_fp.getPkeyId();
		String pvalTxt = the_fp.getpval();
		if(pvalTxt.startsWith("SP:")){
			//System.out.println("STARTS WITH SP: <"+pvalTxt+">");
			//pkeyIdTxt = "protein_id";
			pvalTxt = pvalTxt.substring(3);
			//System.out.println("TRUNCATED TO <"+pvalTxt+">");
		}else if(pvalTxt.startsWith("GB:")){
			//pkeyIdTxt = "genbank_id";
			pvalTxt = pvalTxt.substring(3);
		}else if(pvalTxt.startsWith("FB:")){
			//pkeyIdTxt = "flybase_id";
			pvalTxt = pvalTxt.substring(3);
		}
		return makeGameProperty(the_DOC,pkeyIdTxt,pvalTxt);
	}

	public Element makeGameProperty(Document the_DOC,
			String the_typeTxt,String the_valueTxt){
		//System.out.println("FEATPROP makeGameProperty()!!!");
		Element attrNode = (Element)the_DOC.createElement("property");

		if(the_typeTxt!=null){
			Element typeNode = (Element)the_DOC.createElement("type");
			typeNode.appendChild(the_DOC.createTextNode(the_typeTxt));
			attrNode.appendChild(typeNode);
		}
		if(the_valueTxt!=null){
			Element valueNode = (Element)the_DOC.createElement("value");
			valueNode.appendChild(the_DOC.createTextNode(the_valueTxt));
			attrNode.appendChild(valueNode);
		}
		return attrNode;
	}

	public Element makeGameFeatPropComment(Document the_DOC,
			FeatProp the_fp){
		//System.out.println("FEATPROP makeGameFeatPropComment()!!!");
		String txtTxt = the_fp.getpval();
		String dateTxt = null;
		String tsTxt = null;
		if(txtTxt!=null){
			int indx = txtTxt.indexOf("::DATE:");
			if(indx>0){
				dateTxt = txtTxt.substring(indx+7);
				txtTxt = txtTxt.substring(0,indx);
			}
			if(dateTxt!=null){
				int dindx = dateTxt.indexOf("::TS:");
				if(dindx>0){
					tsTxt = dateTxt.substring(dindx+5);
					dateTxt = dateTxt.substring(0,dindx);
				}
			}
		}
		return makeGameComment(the_DOC,txtTxt,
				the_fp.getPubId(),
				dateTxt,tsTxt);
	}
}



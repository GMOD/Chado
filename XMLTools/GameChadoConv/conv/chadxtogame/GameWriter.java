//GameWriter.java
package conv.chadxtogame;

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
private boolean m_geneOnly = false;

	public GameWriter(String the_infile,String the_outfile,
			int the_DistStart,int the_DistEnd,
			String the_NewREFSTRING,boolean the_geneOnly){
		if(the_infile==null){
			System.exit(0);
		}
		m_InFile = the_infile;
		m_OutFile = the_outfile;
		m_NewREFSPAN = new Span(the_DistStart,the_DistEnd);
		m_NewREFSTRING = the_NewREFSTRING;
		m_geneOnly = the_geneOnly;
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
		csr.parse(m_InFile);
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

		//USE METADATA FROM _APPDATA
		String mdARM=null,mdTITLE=null;
		String mdMIN=null,mdMAX=null,mdRESIDUES=null;
		the_TopNode = the_TopNode;
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			FeatSub gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Appdata){
				System.out.println("FOUND appdata<"
						+gf.getId()+">");
				if(gf.getId().equals("arm")){
					mdARM = ((Appdata)gf).getText();
					System.out.println("ARM<"+mdARM+">");
				}else if(gf.getId().equals("title")){
					mdTITLE = ((Appdata)gf).getText();
					System.out.println("TITLE<"
						+mdTITLE+">");
				}else if(gf.getId().equals("fmin")){
					mdMIN = ((Appdata)gf).getText();
					System.out.println("MIN<"
						+mdMIN+">");
				}else if(gf.getId().equals("fmax")){
					mdMAX = ((Appdata)gf).getText();
					System.out.println("MAX<"
						+mdMAX+">");
				}else if(gf.getId().equals("residues")){
					mdRESIDUES = ((Appdata)gf).getText();
					System.out.println("RESIDUES LEN<"
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

		System.out.println("START WRITING NON ANNOT SEQ FEAT FROM METADATA");
		root.appendChild(makeNonAnnotSeqFeatFromMetadata(the_DOC,
				annotSeqName,mdRESIDUES,"true"));

		//MAP_POSITION
		/***************/
		if(mdARM!=null){
			root.appendChild(makeMapPos(the_DOC,
					annotSeqName,
					mdARM,
					new Span(mdMIN,mdMAX)));
			m_OldREFSTRING = annotSeqName;
		}else{
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = the_TopNode.getGenFeat(i);
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
		/***************/

	/************/
		System.out.println("START WRITING ANNOT FEATURES");
		System.out.println("CURR ANNOT NAME<"+annotSeqName
				+"> OLD<"+m_OldREFSTRING
				+"> NEW<"+m_NewREFSTRING+">");
		//ANNOTATION, SEQUENCE FEATURES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			FeatSub gf = (FeatSub)the_TopNode.getGenFeat(i);
			if(gf.getTypeId()==null){
				System.out.println("SHOULD THIS BE NULL FOR<"+gf.getId()+">");
			}else if(gf.getTypeId().startsWith("gene")){
				root.appendChild(makeAnnotation(the_DOC,(Feature)gf));
//FSSNEW
			}else if(gf.getTypeId().startsWith("sequence")){
				root.appendChild(makeNonAnnotSeqFeat(the_DOC,
						(Feature)gf,"false"));
			}else{
				//System.out.println("\tNOT WRITTEN SINCE UNKNOWN TYPE<"+gf.getTypeId()+">");
			}
		}
		System.out.println("DONE WRITING ANNOTATION FEATURES");
	/************/

		if(m_geneOnly==false){
			System.out.println("START WRITING ANALYSIS FEATURES");
			//COMP_ANAL FEATURES
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = (FeatSub)the_TopNode.getGenFeat(i);
				System.out.println("COMPANAL<"+gf.getisanalysis()+">");
				if(gf.getisanalysis().equals("1")){
					System.out.println("IS_ANALYSIS=1");
					if(gf.getTypeId().startsWith("match")){
					}else{
					}
					m_AnalysisList.add(makeCompAnalysis(
							the_DOC,(Feature)gf));
				}else{
					System.out.println("IS_ANALYSIS=0");
					gf.Display(1);
				}
			}
		}
	/************/
		for(int i=0;i<m_AnalysisList.size();i++){
			System.out.println("\tWRITE ANALFEAT<"+i+">");
			Element el = (Element)m_AnalysisList.get(i);
			root.appendChild(el);
		}
		System.out.println("DONE WRITING ANALYSIS FEATURES");

		System.out.println("START WRITING DELETE FEATURES");
		//DELETE FEATURES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			FeatSub gf = the_TopNode.getGenFeat(i);
			if((gf.getTypeId()!=null)
				&&((gf.getTypeId().startsWith("deleted_"))
				||(gf.getTypeId().startsWith("changed_")))){
					System.out.println("WRITING DELETE FEATURE <"+gf.getId()+"> OF TYPE<"+gf.getTypeId()+">");
					root.appendChild(
						makeModFeat(the_DOC,(GenFeat)gf));
			}
		}
	/*************/
		System.out.println("DONE WRITING DELETE FEATURES");
		System.out.println("VIEW MAPPING");
		Mapping.Display();
		System.out.println("DONE VIEWING MAPPING");
		return root;
	}

	public Element makeModFeat(Document the_DOC,GenFeat the_gf){
		//DEPENDS ON TYPE BEING CHECKED ABOVE
		Element modfeatNode = (Element)the_DOC.createElement(
				the_gf.getTypeId());
		String idStr = the_gf.getId();
		if(idStr!=null){
			int indx = idStr.indexOf(":");
			if(indx>0){
				idStr = idStr.substring(indx+1);
			}
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
		System.out.println("START ANNOTATION");
		Element annotNode = (Element)the_DOC.createElement("annotation");
//FSSNEW
		if(the_gf.getUniqueName()!=null){
			the_gf.setId(the_gf.getUniqueName());
		}

		if(the_gf.getId()!=null){
			annotNode.setAttribute("id",the_gf.getId());
			System.out.println("\tWRITING GAME ANNOT ID<"
					+the_gf.getId()+"> TYPE<"+the_gf.getTypeId()+">");
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
		System.out.println("GENFEAT LIST FOR ANNOTATION <"+the_gf.getId()
				+"> SIZE<"+the_gf.getGenFeatCount()+">");
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			Feature FSgf = (Feature)the_gf.getGenFeat(i);
			System.out.println("\tTRANSCR COMPID<"+FSgf.getId()
					+"> OF TYPE<"+FSgf.getTypeId()+">");

			if(FSgf.getTypeId().equals("chromosome_arm")){
			}else{
				annotNode.appendChild(
						makeFeatureSet(the_DOC,FSgf));
			}
		}

		System.out.println("END ANNOTATION");
		return annotNode;
	}

	public Element makeFeatureSet(Document the_DOC,Feature the_gf){
		System.out.println("START FEATURE_SET");
//FSSNEW
		if(the_gf.getUniqueName()!=null){
			the_gf.setId(the_gf.getUniqueName());
		}

		Element featureSetNode = (Element)the_DOC.createElement("feature_set");
		//name,type,author,date,property
		featureSetNode.setAttribute("id",the_gf.getId());

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
		System.out.println("GENLIST FOR FEATURE_SET <"+the_gf.getId()
				+"> SIZE<"+the_gf.getGenFeatCount()+">");
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
			System.out.println("THE START CODON<"+gf.getId()+">");
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
			System.out.println("\tCOMP FEAT<"
					+gf.getId()+"> OF TYPE<"
					+gf.getTypeId()+">");
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
			System.out.println("THE PROTEINS<"+gf.getId()+">");
			featureSetNode.appendChild(
					makeGameSeq(the_DOC,
							gf.getId(),
							gf.getId(),
							gf.getResidues(),
							gf.getTypeId(),
							gf.getMd5()));
		}
		System.out.println("END FEATURE_SET");
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

		System.out.println("THISFEATSPANID<"+the_gf.getId()
				+"> UN<"+the_gf.getUniqueName()+">");
//YYYYY - NEED TO DIFFERENTIATE BETWEEN A SEQUENCE INSIDE A FEATURE_SET 
//AND A REGULAR FEATURE_SPAN (exon)
		//name,type,seq_relationship,span
		System.out.println("WRITING FEATURESPAN<"+the_gf.getId()+">");
		if(the_gf.getId()!=null){
			featureSpanNode.setAttribute("id",the_gf.getId());
			//PRODUCED SEQ HAS SAME NAME
			if((the_gf.getTypeId()!=null)
//					&&(the_gf.getTypeId().equals("start_codon"))){
					&&(the_gf.getTypeId().equals("protein"))){
				System.out.println("MYFEATAREHERE<"+the_gf.getId()+">");
				featureSpanNode.setAttribute(
					"produces_seq",the_gf.getId()+"_seq");
				featSpanName = the_gf.getId();
			}
		}

		if(featSpanName!=null){
			featureSpanNode.appendChild(makeGenericNode(
					the_DOC,"name",featSpanName));
		}
		if(the_gf.getTypeId()!=null){
			featureSpanNode.appendChild(makeGenericNode(
					//the_DOC,"type",the_gf.getTypeId()));
					the_DOC,"type",translateCVTERM(the_gf.getTypeId())));
		}
		if((the_gf.getFeatLoc()!=null)
				&&(the_gf.getFeatLoc().getSpan()!=null)){
			System.out.print("WRITE GAME FEATSPAN<"+the_gf.getFeatLoc().getSpan()+">");
			Span sp = the_gf.getFeatLoc().getSpan().retreat(
					m_NewREFSPAN.getStart());
			int strand = the_gf.getFeatLoc().getstrand();
			the_gf.getFeatLoc().setSpan(sp);
			System.out.println(" AS RETREATED<"+sp+">");
			featureSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_gf,sp,strand,m_OldREFSTRING,"query",null));
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
			GenFeat the_gf,boolean the_isAnnotation){
		System.out.println("FEATPROP makeAuthPropComm()!!!");

		//  DATE
		//if(the_gf.getDate()!=null){
		//	the_Node.appendChild(makeDateNode(
		//		the_DOC,the_gf.getDate(),the_gf.getDate());
		//}

		for(int i=0;i<((Feature)the_gf).getFeatSynCount();i++){
			FeatSyn fs = ((Feature)the_gf).getFeatSyn(i);
			System.out.println("SYNONYM<"+fs.getSynonym().getname()+">");
			the_Node.appendChild(makeGameProperty(the_DOC,"internal_synonym",fs.getSynonym().getname()));
		}

		//  AUTHOR,PROPERTIES,COMMENTS
		Vector propList = new Vector();
		Vector commentList = new Vector();
		Vector authorList = new Vector();
		for(int i=0;i<((Feature)the_gf).getFeatSubCount();i++){
			FeatSub fs = ((Feature)the_gf).getFeatSub(i);
			System.out.print("\tFP<"+i+">");
			if((fs!=null)&&(fs instanceof FeatProp)){
				FeatProp fp = (FeatProp)fs;
				System.out.print(" KEY<"+fp.getPkeyId()
						+"> VAL<"+fp.getpval()+">");
				if(fp==null){
					System.out.println("SSSSNOTHERE");
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
				}else{
					propList.add(
						makeGameFeatPropReg(the_DOC,fp));
				}
			}
			System.out.println("");
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
		//String tmpaccession = "";
		if(((Feature)the_gf).getDbxrefId()!=null){
			Dbxref d = ((Feature)the_gf).getDbxref();
			//tmpdbname = d.getdbname();
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
		if((the_timestampTxt!=null)&&(the_dateTxt!=null)){
			attrNode.appendChild(
				makeDateNode(the_DOC,
					the_timestampTxt,the_dateTxt));
		}
		return attrNode;
	}

	public Element makeDateNode(Document the_DOC,
			String the_timestamp,String the_date){
		Element dateNode = (Element)the_DOC.createElement("date");
		//if(the_timestamp!=null){
		//	dateNode.setAttribute("timestamp",the_timestamp);
		//}
		if(the_date!=null){
			dateNode.appendChild(the_DOC.createTextNode(the_date));
		}
		return dateNode;
	}

	public Element makeSeqRelNode(Document the_DOC,GenFeat the_gf,Span the_Span,int the_strand,String the_refName,String the_typeName,String the_Align){
		//System.out.println("MAKING SEQRELNODE");
		//BECAUSE SOMETIMES ITS THE 'ALT' SPAN
		//SO NEED TO ACTUALLY PASS IN THE SPAN
		Element seqRelNode = (Element)the_DOC.createElement("seq_relationship");
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
		Element compAnalNode = (Element)the_DOC.createElement("computational_analysis");

		if(the_ca.gettimeaccessioned()!=null){
			compAnalNode.appendChild(makeDateNode(
					the_DOC,"TIMESTAMP",
					the_ca.gettimeaccessioned()));
		}
		System.out.println("NEW REF SPAN<"+m_NewREFSPAN.getStart()
				+".."+m_NewREFSPAN.getEnd()+">");

		if(the_ca.getprogram()!=null){
			System.out.println("COMP_ANAL PROGRAM<"+
					the_ca.getprogram()+">");
			compAnalNode.appendChild(makeGenericNode(the_DOC,
					"program",the_ca.getprogram()));
		}
		if(the_ca.getsourcename()!=null){
			System.out.println("COMP_ANAL SOURCENAME<"+
					the_ca.getsourcename()+">");
			compAnalNode.appendChild(makeGenericNode(the_DOC,
					"database",the_ca.getsourcename()));
		}

		if(the_ca.getprogramversion()!=null){
			System.out.println("COMP_ANAL PROGRAMVERSION<"+
					the_ca.getprogramversion()+">");
			compAnalNode.appendChild(makeGenericNode(the_DOC,
					"version",the_ca.getprogramversion()));
		}

		compAnalNode.appendChild(makeGameProperty(the_DOC,
				"qseq_type","genomic"));
		compAnalNode.appendChild(makeGameProperty(the_DOC,
				"type","Gene Prediction"));


		Element resultSetNode = (Element)the_DOC.createElement(
				"result_set");

		if(the_ca.getId()!=null){
			System.out.println("RESULT_SET ID<"
					+the_ca.getId()+">");
			resultSetNode.setAttribute("id",the_ca.getId());
		}
		if(the_ca.getName()!=null){
			System.out.println("RESULT_SET NAME<"
					+the_ca.getName()+">");
			resultSetNode.appendChild(makeGenericNode(the_DOC,
					"name",the_ca.getName()));
		}
		System.out.println("COMP_ANAL SCORE <"
				+the_ca.getrawscore()+">");

		Vector rSpanList = new Vector();
		//BUILD SPAN LIST
		/***********/
		for(int i=0;i<the_ca.getGenFeatCount();i++){
			GenFeat CAgf = (GenFeat)the_ca.getGenFeat(i);
			System.out.println("XXXYYY START");
			CAgf.Display(2);
			rSpanList.add(CAgf);
		}
		/***********/
		/***********
		for(int i=0;i<the_ca.getCompFeatCount();i++){
			String compId = (String)the_ca.getCompFeat(i);
			Feature CAgf = (Feature)Mapping.Lookup(compId);
			System.out.println("XXX START");
			CAgf.Display();
			System.out.println("XXX END");
			rSpanList.add(CAgf);
		}
		***********/

		//SORT SPAN LIST
		for(int i=0;i<rSpanList.size();i++){
			Feature cai = (Feature)rSpanList.get(i);
			for(int j=(i+1);j<rSpanList.size();j++){
				Feature caj = (Feature)rSpanList.get(j);
				if((cai.getFeatLoc()!=null)&&(cai.getFeatLoc().getSpan()!=null)&&(caj.getFeatLoc()!=null)&&(caj.getFeatLoc().getSpan()!=null)){
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
		System.out.println("DISPLAY RESULT_SET");
		Span resultSetSpan = new Span(0,0);
		for(int i=0;i<rSpanList.size();i++){
			Feature ca = (Feature)rSpanList.get(i);
			if((ca!=null)&&(ca.getFeatLoc()!=null)){
	//ARF
				//Span sp = ca.getFeatLoc().getSpan().retreat(
				//		m_NewREFSPAN.getStart());
				Span sp = ca.getFeatLoc().getSpan();

				resultSetSpan.grow(sp);
				ca.getFeatLoc().setSpan(sp);
				System.out.println("\tRESULT_SPAN<"
					+ca.getFeatLoc().getSpan().toString()+">");
			}else{
				System.out.println("MISSING FEATLOC!!!");
			}
		}

		int strand = -1;
		if(resultSetSpan.isForward()){
			strand = 1;
		}
		System.out.println("PROBLEM COMP_ANALYSIS<"+m_OldREFSTRING+">");
		resultSetNode.appendChild(makeSeqRelNode(
				the_DOC,the_ca,
				resultSetSpan,
				strand,m_OldREFSTRING,"query",null));

		//WRITE SPAN LIST
		for(int i=0;i<rSpanList.size();i++){
			Feature ca = (Feature)rSpanList.get(i);
			if((ca!=null)&&(ca.getFeatLoc()!=null)){
				Element caresSpan = makeNewResultSpan(
						the_DOC,ca,
						ca.getTypeId(),
						ca.getrawscore());
				resultSetNode.appendChild(caresSpan);
			}
		}
		compAnalNode.appendChild(resultSetNode);

		System.out.println("\n");
		return compAnalNode;
	}

	public Element makeNewResultSpan(Document the_DOC,Feature the_ca,
			String the_typeId,String the_score){
		System.out.println("makeNewResultSpan()");
		Element resultSpanNode = (Element)the_DOC.createElement("result_span");
		if(the_ca.getId()!=null){
			resultSpanNode.setAttribute("id",the_ca.getId());
		}
		if(the_ca.getName()!=null){
			resultSpanNode.appendChild(makeGenericNode(
					the_DOC,"name",the_ca.getName()));
		}
		System.out.println("\tRESULT_SPAN NAME <"
				+the_ca.getrawscore()+">");
		System.out.println("\tRESULT_SPAN SCORE <"
				+the_ca.getrawscore()+">");

		String queryName = m_OldREFSTRING;
		String subjName = "";
		for(int i=0;i<the_ca.getGenFeatCount();i++){
			GenFeat gf = (GenFeat)the_ca.getGenFeat(i);
			System.out.println("GGGGF<"+gf.getName()+">");
			//subjName = gf.getName();
			subjName = gf.getUniqueName();
//KLUDGE - FIX
			if(subjName!=null){
				break;
			}
		}
		
		if(the_ca.getFeatLoc()!=null){
			Span sp = the_ca.getFeatLoc().getSpan();

	//ARF
			//Span spAdv = sp.retreat(m_NewREFSPAN.getStart());
			//Span spAdv = sp;
			Span spAdv = sp.advance(m_NewREFSPAN.getStart());

			System.out.println("\tRESULT_SET FEATLOC <"
				+sp.toString()+"> ADV <"+spAdv.toString()
				+"> LEN<"+sp.getLength()
				+"> STRAND<"+the_ca.getFeatLoc().getstrand()+">");
			int strand = 1;
			if(the_ca.getAltFeatLoc()!=null){
				strand = the_ca.getAltFeatLoc().getstrand();
			}
			System.out.println("PROBLEM NEW_RESULT_SPAN<"+queryName+">");
			resultSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_ca,sp,strand,
					queryName,"query",
					the_ca.getFeatLoc().getAlign()));
			System.out.println("FSS ALIGN<"+the_ca.getFeatLoc().getAlign()+">");
		}
		//SUBJECT
		if(the_ca.getAltFeatLoc()!=null){
			Span altsp = the_ca.getAltFeatLoc().getSpan();
	//ARF
			//Span altspRet = altsp.retreat(m_NewREFSPAN.getStart());
			Span altspRet = altsp;
			System.out.println("\tRESULT_SET ALTFEATLOC <"
				+altsp.toString()+"> RET <"+altspRet.toString()
				+"> LEN<"+altsp.getLength()
				+"> STRAND<"+the_ca.getAltFeatLoc().getstrand()+">");
			int strand = the_ca.getAltFeatLoc().getstrand();
			System.out.println("PROBLEM NEW_RESULT_SPAN_ALT<"+subjName+">");
			resultSpanNode.appendChild(makeSeqRelNode(
					//the_DOC,the_ca,altsp,strand,subjName,"subject"));
					the_DOC,the_ca,altspRet,strand,
					subjName,"subject",
					the_ca.getFeatLoc().getAlign()));
			System.out.println("FSS ALIGN<"+the_ca.getFeatLoc().getAlign()+">");
		}

		return resultSpanNode;
	}

	public Element makeGameSpan(Document the_DOC,Span testSpan,int the_strand){
		Element gameSpanNode = (Element)the_DOC.createElement("span");
		//System.out.println("+++GAMESPAN STRAND<"+the_strand+">");
		gameSpanNode.appendChild(makeGenericNode(
				the_DOC,"start",(""+testSpan.getStart())));
		gameSpanNode.appendChild(makeGenericNode(
				the_DOC,"end",(""+testSpan.getEnd())));
		return gameSpanNode;
	}

	public Element makeGameFeatPropReg(Document the_DOC,FeatProp the_fp){
		System.out.println("FEATPROP makeGameFeatPropReg()!!!");
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
		System.out.println("FEATPROP makeGameProperty()!!!");
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
		System.out.println("FEATPROP makeGameFeatPropComment()!!!");
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

/**********************
	public Element makeGameFeatProp(Document the_DOC,FeatProp the_fp){
		if(the_fp.getPkeyId()==null){
			System.out.println("==========SHOULDNT BE NULL EITHER");
			return null;
		}else if(the_fp.getPkeyId().equals("comment")){
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
					//the_fp.getpub_id(),
					the_fp.getPubId(),
					dateTxt,tsTxt);

		}else if(the_fp.getPkeyId().equals("author")){
			Element authNode = (Element)the_DOC.createElement("author");
			authNode.appendChild(the_DOC.createTextNode(
					the_fp.getpval()));
			return authNode;
		}else{
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
	}
**********************/



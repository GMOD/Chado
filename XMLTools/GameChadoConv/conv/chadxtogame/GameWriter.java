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
private String m_RESIDUES = null;

//FOR BUILDING PREAMBLE
//private HashSet m_CVList;
//private HashSet m_CVTERMList;
//private HashSet m_PUBList;
//private HashSet m_EXONList;

private String m_ARMNAME = null;

String ANNORES_OFFSET = "\n      ";
String ANNORES_OFFSET_END = "\n    ";
String GAMERES_OFFSET = "\n          ";
String GAMERES_OFFSET_END = "\n        ";

//BECAUSE ANALYSIS FEATURES MAY BE EMBEDDED
//THEY NEED TO BE COLLECTED ALONG THE WAY AND
//PRINTED OUT IN THE END
private Vector m_AnalysisList = null;

private HashMap m_AnalSeqList = null;

public static int CONVERT_ALL = 0;
public static int CONVERT_GENE = 1;
public static int CONVERT_COMP = 2;
private int m_readMode = 0;

private String PROP_FILE = "/users/smutniak/ChadoXML/GameChadoConv/CTG.properties";
private Vector m_CaSingleSpanList = null;
private Vector m_CaDoubleSpanList = null;

	public GameWriter(String the_infile,String the_outfile,
			int the_DistStart,int the_DistEnd,
			String the_NewREFSTRING,int the_readMode){
		if(the_infile==null){
			System.exit(0);
		}
		m_InFile = the_infile;
		m_OutFile = the_outfile;
		m_NewREFSPAN = new Span(the_DistStart,the_DistEnd,null);
		m_NewREFSTRING = the_NewREFSTRING;
		//m_geneOnly = the_geneOnly;
		m_readMode = the_readMode;
		if(m_OutFile!=null){
			System.out.println("\n********************************");
			System.out.println("START C->G\n\t\tINFILE<"+m_InFile
					+">\n\t\tOUTFILE<"+m_OutFile
					+">\n\t\tDIST<"+m_NewREFSPAN.toString()
					+">\n\t\tNewREFSTRING<"+m_NewREFSTRING+">\n");
		}

		m_AnalSeqList = new HashMap();

		m_AnalysisList = new Vector();

		CAProp cap = new CAProp(PROP_FILE);
		m_CaSingleSpanList = cap.getPropList("CA_SINGLE_SPAN");
		System.out.println("Known Single Span Programs <"
				+m_CaSingleSpanList.size()+">");
		for(int i=0;i<m_CaSingleSpanList.size();i++){
			String progType = (String)m_CaSingleSpanList.get(i);
			System.out.println("\tPROG<"+progType+">");
		}

		m_CaDoubleSpanList = cap.getPropList("CA_DOUBLE_SPAN");
		System.out.println("Known Double Span Programs <"
				+m_CaDoubleSpanList.size()+">");
		for(int i=0;i<m_CaDoubleSpanList.size();i++){
			String progType = (String)m_CaDoubleSpanList.get(i);
			System.out.println("\tPROG<"+progType+">");
		}
		System.out.print("\n");
	}

	public void ChadoToGame(){
		//PARSE CHADO FILE
		if(m_InFile!=null){
			//memoryInfo();
			ChadoSaxReader csr = new ChadoSaxReader();
			int resp = csr.parse(m_InFile,m_readMode);
			if(resp>=0){
				//memoryInfo();
				GenFeat TopNode = csr.getTopNode();
				csr = null;
				if(m_OutFile!=null){
					writeFile(TopNode,m_OutFile);
					System.out.println("DONE C->G INFILE<"+m_InFile
							+"> OUTFILE<"+m_OutFile+">\n");
				}else{
					System.out.println("No Output File");
				}
			}else{
				System.out.println("INPUT FILE <"+m_InFile+"> NOT PARSED");
			}
		}else{
			System.out.println("No Input File");
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
			System.out.println("DONE MAKING ROOT, TIME TO WRITE");
			gf = null;
		//System.out.println("CLEANUP 5");
		//memoryInfo();
		System.gc();
		//memoryInfo();
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
		String mdMIN=null,mdMAX=null;
		the_TopNode = the_TopNode;
		if(the_TopNode==null){
			return null;
		}
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
					m_RESIDUES = ((Appdata)gf).getText();
					System.out.println("\tRESIDUES LEN<"
						+m_RESIDUES.length()+">");
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
				m_NewREFSPAN = new Span(mdMIN,mdMAX,null);
				//INTERBASE CONVERSION
				m_NewREFSPAN.setStart(m_NewREFSPAN.getStart()+1);
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

		//System.out.println("START WRITING METADATA RELATED FEATURES");
		root.appendChild(makeNonAnnotSeqFeatFromMetadata(the_DOC,
				annotSeqName,m_RESIDUES,"true"));

		//MAP_POSITION
		if(mdARM!=null){
			//System.out.println("\tFOUND ARM STRING<"+mdARM+">");
			Span mapSpan = new Span(mdMIN,mdMAX,null);
			//INTERBASE CONVERSION
			mapSpan.setStart(mapSpan.getStart()+1);
			root.appendChild(makeMapPos(the_DOC,
					annotSeqName,
					mdARM,mapSpan));
			m_OldREFSTRING = annotSeqName;
		}else{
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = the_TopNode.getGenFeat(i);
				//System.out.println("\tFEATSUB TYPE<"+gf.getTypeId()
				//		+"><"+gf.getId()+">");
				if((gf.getTypeId()!=null)
						&&(gf.getTypeId().startsWith("arm"))){
					//System.out.println("MAP_POS FEATURE<"
					//		+gf.getTypeId()+">");
					m_ARMNAME = ((GenFeat)gf).getUniqueName();
					root.appendChild(makeMapPos(the_DOC,
							annotSeqName,
							m_ARMNAME,
							m_NewREFSPAN));
					m_OldREFSTRING = gf.getId();
				}
			}
		}
		//System.out.println("DONE WRITING METADATA RELATED FEATURES");
		//memoryInfo();

		if((m_readMode==CONVERT_ALL)||(m_readMode==CONVERT_GENE)){
			//System.out.println("START WRITING ANNOT FEATURES");
			//System.out.println("CURR ANNOT NAME<"+annotSeqName
			//		+"> OLD<"+m_OldREFSTRING
			//		+"> NEW<"+m_NewREFSTRING+">");
			//ANNOTATION, SEQUENCE FEATURES
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = (FeatSub)the_TopNode.getGenFeat(i);
				if(gf.getTypeId()==null){
					//MUST BE METADATA STFF
				}else if(gf.getTypeId().startsWith("gene")){
					root.appendChild(makeAnnotation(the_DOC,
							(Feature)gf));
					gf = null;
				}else if(gf.getTypeId().startsWith("transposable_element")){
					if((((Feature)gf).getName()!=null)
						&&(((Feature)gf).getName().startsWith("JOSH"))){
						//IGNORING JOSHTRANSPOSON FEAT (BUT KEEP EVIDENCE)
					}else{
						//System.out.println("MAKING TRANSPOSON");
						root.appendChild(makeTransposon(the_DOC,
								(Feature)gf));
						gf = null;
					}
				}else if(gf.getTypeId().startsWith("sequence")){
					root.appendChild(makeNonAnnotSeqFeat(the_DOC,
							(Feature)gf,"false"));
					gf = null;
				}else if(gf.getTypeId().startsWith("annot_sequence")){
					gf = null;
				}else if(gf.getTypeId().startsWith("arm")){
					gf = null;
				}else{
					//System.out.println("\tNOT WRITTEN SINCE UNKNOWN TYPE<"
					//		+gf.getTypeId()+">");
				}
			}
			System.out.println("DONE WRITING ANNOTATION FEATURES");
		}
		//System.out.println("--------------------------------");
		//System.out.println("POST ANNOTATION MEMORY CLEANUP");
		//memoryInfo();
		System.gc();
		//memoryInfo();

		if((m_readMode==CONVERT_ALL)||(m_readMode==CONVERT_COMP)){
			System.out.println("START WRITING ANALYSIS FEATURE");
			//COMP_ANAL FEATURES
			int cnt = the_TopNode.getGenFeatCount();
			//System.out.println("CLEANUP START THERE ARE <"
			//		+cnt+"> COMP_ANALS");
			//CREATE FEATURE LIST
			Vector compAnalList = new Vector();
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				FeatSub gf = (FeatSub)the_TopNode.getGenFeat(i);
				if(gf.getisanalysis().equals("1")){
					//System.out.println("\tIS_ANALYSIS=1");
					//System.out.println("ANALYSIS<"
					//	+((Feature)gf).getName()
					//	+"> TYPE<"
					//	+((Feature)gf).getTypeId()+">");
					compAnalList.add(gf);
					//m_AnalysisList.add(makeCompAnalysis(
					//		the_DOC,(Feature)gf));
					//System.out.println("ADDING COMP_ANALYSIS\n");
				}else{
					//System.out.println("\tIS_ANALYSIS=0");
					//gf.Display(1);
				}
			}

			//GROUPS EACH FEATURE BY TYPE
			//AND CREATES ONE COMP_ANAL PER TYPE
			Vector keyList = new Vector();
			HashMap m_CAList = new HashMap();
			for(int i=0;i<compAnalList.size();i++){
				//FeatSub gfi = (FeatSub)compAnalList.get(i);
				Feature gfi = (Feature)(FeatSub)compAnalList.get(i);
				//DETERMINING THE PROPER GROUPING INTO COMPUTATIONAL_ANALYSIS
				String compType = gfi.getprogram()+gfi.getsourcename();
				Vector compVec = null;
				if(!(m_CAList.containsKey(compType))){
					//NEW TYPE, MAKE A NEW VECTOR FOR IT
					compVec = new Vector();
					compVec.add(gfi);
					m_CAList.put(compType,compVec);
					keyList.add(compType);
				}else{
					compVec = (Vector)m_CAList.get(compType);
					compVec.add(gfi);
				}
			}
			for(int i=0;i<keyList.size();i++){
				String key = (String)keyList.get(i);
				//System.out.println("COMP_ANAL KEY <"+key+">");
				Vector v = (Vector)m_CAList.get(key);
				m_AnalysisList.add(makeCompAnalysisFromVec(
						the_DOC,v));
				for(int j=0;j<v.size();j++){
					Feature fs = (Feature)(FeatSub)v.get(j);
					//System.out.println("\tKEY TYPE<"+fs.getprogram()+">");
				}
			}
		}

		//MAKE ANALYSIS SEQUENCES
		Set keySet = m_AnalSeqList.keySet();
		Iterator it = keySet.iterator();
		while(it.hasNext()){
			String key = (String)it.next();
			Element el = (Element)m_AnalSeqList.get(key);
			root.appendChild(el);
		}
		m_AnalSeqList = null;

		//MAKE ANALYSISES
		for(int i=0;i<m_AnalysisList.size();i++){
			//System.out.println("\tWRITE ANALFEAT<"+i+">");
			Element el = (Element)m_AnalysisList.get(i);
			root.appendChild(el);
		}
		m_AnalysisList = null;

		Mapping.clear();
		//System.out.println("POST ANALYSIS MEMORY CLEANUP");
		//memoryInfo();
		System.gc();
		//memoryInfo();
		System.out.println("DONE WRITING ANALYSIS FEATURES");

		System.out.println("START WRITING CHANGED/DELETED FEATURES");
		//DELETE FEATURES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			FeatSub gf = the_TopNode.getGenFeat(i);
			if((gf.getTypeId()!=null)
				&&((gf.getTypeId().startsWith("deleted_"))
				||(gf.getTypeId().startsWith("changed_")))){
					System.out.println("WRITING CHANGE/DELETE FEATURE <"
							+gf.getId()+"> OF TYPE<"
							+gf.getTypeId()+">");
					root.appendChild(
						makeModFeat(the_DOC,(GenFeat)gf));
			}
		}
		System.out.println("DONE WRITING CHANGED/DELETED FEATURES");

		//System.out.println("FINAL MEMORY CLEANUP");
		//memoryInfo();
		the_TopNode = null;
		System.gc();
		//memoryInfo();

		return root;
	}

	private void memoryInfo(){
		Runtime rt = Runtime.getRuntime();
		System.out.println("MEMORY:");
		System.out.println("\tTotal: <"+rt.totalMemory()+">");
		System.out.println("\tMax:   <"+rt.maxMemory()+">");
		System.out.println("\tFree:   <"+rt.freeMemory()+">");
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

	public String getAlignSubstring(Span the_span,int the_strand){
		//System.out.println("ALIGNSUBSTRING<"+the_span+"> STRAND<"+the_strand+">");
		if(the_span!=null){
			boolean doneBeenReversed = false;
			int st = the_span.getStart();
			int en = the_span.getEnd();
			if(st>en){
				int tmp = st;
				st = en;
				en = tmp;
				doneBeenReversed = true;
				System.out.println("\tREVERSED - SHOULD NEVER HAPPEN");
			}
			if(the_strand!=1){
				doneBeenReversed = true;
			}
			String res = null;
			if((m_RESIDUES!=null)&&(st>0)&&(en<=m_RESIDUES.length())){
				//System.out.println("\tTRUNCATED");
				res = m_RESIDUES.substring(st-1,en);
				if(doneBeenReversed){
					//System.out.println("REVERSING");
					res = SeqUtil.reverseComplement(res);
				}
				return res;
			}
		}
		return null;
	}

	public String formatResidues(String the_res){
		if(the_res==null){
			return null;
		}
		StringBuffer sb = new StringBuffer();
		while((the_res!=null)&&(the_res.length()>50)){
			sb.append("\n        "+the_res.substring(0,50));
			//the_res = the_res.substring(51);
			the_res = the_res.substring(50);
		}
		if(the_res!=null){
			sb.append("\n        "+the_res);
		}
		return sb.toString();
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

	public Element makeTransposon(Document the_DOC,Feature the_gf){
		//System.out.println("START TRANSPOSON<"+the_gf.getId()
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
		annotNode = makeAuthPropComm(annotNode,the_DOC,the_gf,true);

		//System.out.println("TRANSPOSON FEATLOC<"
		//		+the_gf.getFeatLoc().getSpan().toString()+">");
		annotNode.appendChild(makeTransposonSet(the_DOC,the_gf));

		//System.out.println("END TRANSPOSON");
		return annotNode;
	}

	public Element makeTransposonSet(Document the_DOC,Feature the_gf){
		//System.out.println("MAKING TRANSPOSON_SET");
		String DUMMYSUFFIX = "-RA";
		Element featureSetNode = (Element)the_DOC.createElement("feature_set");
		featureSetNode.setAttribute("id",the_gf.getId()+DUMMYSUFFIX);
		//PRODUCED SEQ HAS SAME NAME
		String producesSeq = null;
		if(the_gf.getName()!=null){
			producesSeq = the_gf.getId()+DUMMYSUFFIX;//+"_seq";
			featureSetNode.setAttribute(
				"produces_seq",producesSeq);
		}
		if(producesSeq!=null){
			featureSetNode.setAttribute("produces_seq",producesSeq);
		}

		//NAME
		if(the_gf.getName()!=null){
			featureSetNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()+DUMMYSUFFIX));
		}
		//TYPE
		if(the_gf.getTypeId()!=null){
			featureSetNode.appendChild(makeGenericNode(
					the_DOC,"type",
					"transcript"));
					//translateCVTERM(the_gf.getTypeId())));
		}

		//WRITE 'EXON'
		Span sp = the_gf.getFeatLoc().getSpan();
		//System.out.print("\t\tEXON<"+the_gf.getId()
		//		+"> SP<"+sp.toString()+">");
		Span spRet = sp.retreat((m_NewREFSPAN.getStart()-1));
		//INTERBASE COMPENSATION
		spRet = new Span(spRet.getStart()+1,spRet.getEnd(),spRet.getSrc());
		the_gf.getFeatLoc().setSpan(spRet);
		//System.out.println("TO<"+spRet.toString()+">");

		Element featureSpanNode = (Element)
				the_DOC.createElement("feature_span");
		if(the_gf.getName()!=null){
			String featSpanName = the_gf.getName()+":1";
			featureSpanNode.appendChild(makeGenericNode(
					the_DOC,"name",featSpanName));
		}
		int strand = the_gf.getFeatLoc().getstrand();
		the_gf.getFeatLoc().setSpan(spRet);
		//String featLocSrc = the_gf.getFeatLoc().getSpan().getSrc();
		//System.out.println("AAA1<"+featLocSrc+"> CMP TO FTSPN<"+m_OldREFSTRING+">");
		featureSpanNode.appendChild(makeSeqRelNode(
				the_DOC,the_gf,spRet,strand,
				m_OldREFSTRING,"query",null));

		featureSetNode.appendChild(featureSpanNode);

		//WRITE CDNA SEQUENCE
		if(the_gf.getResidues()!=null){
			featureSetNode.appendChild(
					makeGameSeq(the_DOC,
					the_gf.getId(),
					the_gf.getId(),
					the_gf.getResidues(),
					the_gf.getTypeId(),
					the_gf.getMd5()));
			System.out.println("\t\tCDNA<"+the_gf.getId()
					+"> SP<"+the_gf.getFeatLoc().getSpan()+">");
		}
		//System.out.println("ENDING TRANSPOSON_SET");
		return featureSetNode;
	}

	public Element makeAnnotation(Document the_DOC,Feature the_gf){
		System.out.println("START GAME ANNOTATION <"+the_gf.getId()
				+"> TYPE<"+the_gf.getTypeId()
				+"> SIZE<"+the_gf.getGenFeatCount()+">");
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

//SCAN FOR TRANSCRIPTS OF TYPE 'pseudogene', AND TAKE APPROPRIATE ACTION
		String newAnnotType = null;
		String forceType = null;
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			Feature FSgf = (Feature)the_gf.getGenFeat(i);
			String FStype = FSgf.getTypeId();
			if(FStype!=null){
				if((FStype.equalsIgnoreCase("pseudogene"))
					||(FStype.equalsIgnoreCase("snoRNA"))
					||(FStype.equalsIgnoreCase("snRNA"))
					||(FStype.equalsIgnoreCase("ncRNA"))
					||(FStype.equalsIgnoreCase("tRNA"))
					||(FStype.equalsIgnoreCase("rRNA"))
					||(FStype.equalsIgnoreCase("nuclear_micro_RNA_coding_gene"))){
					newAnnotType = FStype;
					//System.out.println("NNNNN ANNOTTYPE SET FROM<"
					//	+newAnnotType+"> TO <transcript>");
					//FSgf.setTypeId("transcript");
					forceType = "transcript";
				}
			}
		}

		if(newAnnotType!=null){
			the_gf.setTypeId(newAnnotType);
			annotNode.appendChild(makeGenericNode(
					the_DOC,"type",newAnnotType));
		}else if(the_gf.getTypeId()!=null){
			annotNode.appendChild(makeGenericNode(
					the_DOC,"type",the_gf.getTypeId()));
		}

		//AUTHOR,PROPERTIES,COMMENTS
		annotNode = makeAuthPropComm(annotNode,the_DOC,the_gf,true);

		//FEATURE_SET
/***********/
//MEMEME
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			Feature FSgf = (Feature)the_gf.getGenFeat(i);
			//System.out.println("\tTRANSCR COMPID<"+FSgf.getId()
			//		+"> OF TYPE<"+FSgf.getTypeId()+">");
			//System.out.println("\t\tHAS <"+FSgf.getFeatDbxrefCount()
			//		+"> DBXREFS");
			if(FSgf.getTypeId().equals("mRNA")){
				for(int k=0;k<((Feature)FSgf).getFeatDbxrefCount();k++){
					FeatDbxref fd = FSgf.getFeatDbxref(k);
					Dbxref d = fd.getDbxref();
					if(d!=null){
						//System.out.println("FEATDBXREFTOSTRING<"
						//		+d.toString()+">");
						if((d.getDBId()!=null)
							  &&(d.getaccession()!=null)){
							annotNode.appendChild(
									makeGameDbxref(
									the_DOC,
									d.getDBId(),
									d.getaccession()));
						}
					}
				}
			}
			for(int j=0;j<FSgf.getGenFeatCount();j++){
				Feature subgf = (Feature)FSgf.getGenFeat(j);
				//System.out.println("\t\tSUB TRANSCR COMPID<"+subgf.getId()
				//		+"> OF TYPE<"+subgf.getTypeId()+">");
				//System.out.println("\t\t\tHAS <"+subgf.getFeatDbxrefCount()+"> DBXREFS");
				if(subgf.getTypeId().equals("protein")){
				for(int k=0;k<((Feature)subgf).getFeatDbxrefCount();k++){
					FeatDbxref fd = subgf.getFeatDbxref(k);
					Dbxref d = fd.getDbxref();
					if(d!=null){
						//System.out.println("FEATDBXREFTOSTRING<"
						//		+d.toString()+">");
						if((d.getDBId()!=null)
							  &&(d.getaccession()!=null)){
							annotNode.appendChild(
									makeGameDbxref(
									the_DOC,
									d.getDBId(),
									d.getaccession()));
						}
					}
				}
				}
			}
		}
/***********/

		for(int i=0;i<the_gf.getGenFeatCount();i++){
			Feature FSgf = (Feature)the_gf.getGenFeat(i);
			if(FSgf.getTypeId().equals("chromosome_arm")){
			}else{
				annotNode.appendChild(
						makeFeatureSet(the_DOC,FSgf,forceType));
			}
		}

		//System.out.println("END ANNOTATION");
		return annotNode;
	}

	public Element makeFeatureSet(Document the_DOC,Feature the_gf,String the_forceType){
		//System.out.println("\tSTART GAME FEATURE_SET ID<"+the_gf.getId()
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
			producesSeq = the_gf.getId();//+"_seq";
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
		if(the_forceType!=null){
			featureSetNode.appendChild(makeGenericNode(
					the_DOC,"type",the_forceType));
		}else if(the_gf.getTypeId()!=null){
			//System.out.println("NNNN FSTYPE<"+the_gf.getTypeId()+">");
			featureSetNode.appendChild(makeGenericNode(
					the_DOC,"type",translateCVTERM(
					the_gf.getTypeId())));
		}

		//AUTHOR
		featureSetNode = makeAuthPropComm(
				featureSetNode,the_DOC,the_gf,false);

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
			String scID = the_gf.getId();
			//scID = gf.getId();
			scID = textReplace(scID,"_seq","").trim();
			//System.out.println("START_CODON ID<"+scID
			//		+"> NAME<"+gf.getName()+">");
			Feature ngf = new Feature(scID);
			String scNAME = gf.getName();
			scNAME = textReplace(scNAME,"_seq","").trim();
			scNAME = textReplace(scNAME,"-P","-R");
			ngf.setName(scNAME);
			ngf.setTypeId("start_codon");
			ngf.setFeatLoc(gf.getFeatLoc());
			if(gf.getFeatLoc()!=null){
				Span tmpSpan = ngf.getFeatLoc().getSpan();
				Span tstSpan = tmpSpan;
				tstSpan = tstSpan.retreat(m_NewREFSPAN.getStart()-2);
				//System.out.println("PROTSPAN<"+tstSpan+">");
				if(tmpSpan!=null){
					//System.out.print("\t\tSTART_CODON SP<"
					//		+tmpSpan+">");
					if(gf.getFeatLoc().getstrand()==1){
						tmpSpan = new Span(
						tmpSpan.getStart(),
						tmpSpan.getStart()+2,
						tmpSpan.getSrc());
					}else{
						tmpSpan = new Span(
						tmpSpan.getEnd()-3,
						tmpSpan.getEnd()-1,
						tmpSpan.getSrc());
					}
					tmpSpan = tmpSpan.retreat(
							(m_NewREFSPAN.getStart()-2));
					//System.out.println(" TO<"+tmpSpan+">");
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
					int strandi = gfi.getFeatLoc().getstrand();
					int strandj = gfj.getFeatLoc().getstrand();
					if(gfj.getFeatLoc().getSpan().precedes(gfi.getFeatLoc().getSpan(),strandi,strandj)){
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

			Span sp = gf.getFeatLoc().getSpan();
			//System.out.print("\t\tEXON<"+gf.getId()
			//		+"> SP<"+sp.toString()+">");
			Span spRet = sp.retreat((m_NewREFSPAN.getStart()-1));
			//INTERBASE COMPENSATION
			spRet = new Span(spRet.getStart()+1,spRet.getEnd(),spRet.getSrc());
			gf.getFeatLoc().setSpan(spRet);
			//System.out.println("TO<"+spRet.toString()+">");

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
			//System.out.println("\t\tCDNA<"+the_gf.getId()
			//		+"> SP<"+the_gf.getFeatLoc().getSpan()+">");
		}

		//WRITE PROTEIN SEQUENCE
		String protID = textReplace(the_gf.getId(),"-R","-P");
		for(int i=0;i<protList.size();i++){ //SHOULD ONLY BE ONE
			Feature gf = (Feature)protList.get(i);
			featureSetNode.appendChild(
					makeGameSeq(the_DOC,
							protID,
							protID,
							gf.getResidues(),
							gf.getTypeId(),
							gf.getMd5()));
			//System.out.println("\t\tPROT<"+protID
			//		+"> SP<"+gf.getFeatLoc().getSpan()+">");
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
						the_gf.getId());//+"_seq");
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
			int strand = the_gf.getFeatLoc().getstrand();
			the_gf.getFeatLoc().setSpan(sp);
			String featLocSrc = the_gf.getFeatLoc().getSpan().getSrc();
			//System.out.println("AAA2<"+featLocSrc
			//		+"> CMP TO FTSPN<"+m_OldREFSTRING+">");
			featureSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_gf,sp,strand,
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
			seqNode.setAttribute("id",the_Id);//+"_seq");
		}
		//LENGTH
		seqNode.setAttribute("length",""+countLength(the_Residues));
/****/
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
					the_DOC,"name",the_Id));//+"_seq"));
		}
		//RESIDUES
		if(the_Residues!=null){
			seqNode.appendChild(makeGenericNode(the_DOC,"residues",
					formatResidues(the_Residues)));
		}else{
			System.out.println("EXITING - NO RESIDUES FOR ID <"+the_Id+"> TYPE<"+the_TypeId+">");
			System.exit(0);
		//	seqNode.appendChild(makeGenericNode(the_DOC,"residues",
		//			formatResidues("RESIDUES_NOT_AVAILABLE")));
		}
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

	public Element makeAuthPropComm(Element the_Node,Document the_DOC,
			Feature the_gf,boolean the_isAnnotation){

		//System.out.println("MAKE_AUTH_PROP_COMM<"+the_gf.getId()+">");
		//  DATE
		//if(the_gf.gettimeaccessioned()!=null){
		//	the_Node.appendChild(makeDateNode(
		//		the_DOC,the_gf.gettimeaccessioned()));
		//}
		if(the_gf.gettimelastmodified()!=null){
			the_Node.appendChild(makeDateNode(
				the_DOC,the_gf.gettimelastmodified()));
		}

		/*****************/
		for(int i=0;i<((Feature)the_gf).getFeatSynCount();i++){
			FeatSyn fs = ((Feature)the_gf).getFeatSyn(i);
			//System.out.println("GAMEWRITER FEATSYN<"
			//		+fs.getSynonym().getname()
			//		+"> INTERNAL<"+fs.getisinternal()+">");
			if(fs.getSynonym().getname()!=null){
				if(fs.getisinternal().equals("1")){
					//System.out.println("MAKING INTERNAL_SYNONYM OF NAME");
					the_Node.appendChild(makeGameProperty(the_DOC,
							"internal_synonym",
							fs.getSynonym().getname()));
				}else{
					//System.out.println("MAKING SYNONYM");
						the_Node.appendChild(makeGenericNode(
								the_DOC,"synonym",
								fs.getSynonym().getname()));
				}
			}else{
				System.out.println("WARNING: NULL SYNONYM NAME FOR <"
						+the_gf.getId()+">");
			}
		}
		/*****************/
		for(int i=0;i<((Feature)the_gf).getFeatCVTermCount();i++){
			FeatCVTerm fc = ((Feature)the_gf).getFeatCVTerm(i);
			//System.out.println("FEATURE_CVTERM<"+fc.toString()+">");
		}

		//  AUTHOR,PROPERTIES,COMMENTS
		Vector propList = new Vector();
		Vector commentList = new Vector();
		Vector authorList = new Vector();

		for(int i=0;i<((Feature)the_gf).getFeatSubCount();i++){
			FeatSub fs = ((Feature)the_gf).getFeatSub(i);
			if((fs!=null)&&(fs instanceof FeatProp)){
				FeatProp fp = (FeatProp)fs;
				if(fp==null){
				}else if(fp.getPkeyId()==null){
					//DO NOTHING
				}else if(fp.getPkeyId().equals("comment")){
					commentList.add(
						makeGameFeatPropComment(
							the_DOC,fp));
				//}else if(fp.getPkeyId().equals("author")){
				}else if(fp.getPkeyId().equals("owner")){
					authorList.add(
						makeGenericNode(the_DOC,
							"author",fp.getpval()));
				}else if(fp.getPkeyId().equals("protein_id")){
					propList.add(
						makeGameFeatPropReg(the_DOC,fp));
				}else{
					//System.out.println("\tUNUSED PROP KEY<"
					//		+fp.getPkeyId()+"> VAL<"
					//		+fp.getpval()+">");
				}
			}
		}

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
				//}else if(fp.getPkeyId().equals("author")){
				}else if(fp.getPkeyId().equals("owner")){
				}else if(!(fp.getPkeyId().equals("protein_id"))){
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
			//System.out.println("DBXREFTOSTRING<"+d.toString()+">");
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
			//System.out.println("FEATDBXREFTOSTRING<"+d.toString()+">");
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

		//System.out.println("END MAKE_AUTH_PROP_COMM<"+the_gf.getId()+">\n");
		return the_Node;
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
				makeDateNode(the_DOC,the_dateTxt));
		}
		return attrNode;
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
		//System.out.println("GW: MAKING SEQRELNODE");
		//BECAUSE SOMETIMES ITS THE 'ALT' SPAN
		//SO NEED TO ACTUALLY PASS IN THE SPAN
		Element seqRelNode = (Element)the_DOC.createElement(
				"seq_relationship");
		if(the_typeName!=null){
			seqRelNode.setAttribute("type",the_typeName);
		}else{
			seqRelNode.setAttribute("type","TYPE_UNKNOWN");
		}
		//System.out.println("GW: SEQ_REL_NODE SEQ_ID<"+the_refName
		//		+"> FOR SPAN<"+the_Span.toString()+">");
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
		//System.out.println("\t\t\tSEQ_REL SPAN<"+the_Span.toString()
		//		+"> TYPE<"+the_typeName+"> SEQ<"+the_refName+">");
		return seqRelNode;
	}

	public Element makeAnalSeq(Document the_DOC,
			String the_id,String the_length,
			String the_md5,String the_name,
			String the_dbname,String the_dbacc,
			String the_description,
			String the_residues){
		String tmpres = the_residues;
		if((the_residues!=null)&&(the_residues.length()>10)){
			tmpres = the_residues;
		}
		//System.out.println("\tQUERY ID<"+the_id
		//		+"> SEQLEN<"+the_length
		//		+"> MD5<"+the_md5
		//		+"> NAME <"+the_name
		//		+">\n\t\tDESC <"+the_description
		//		+">\n\t\tRES<"+tmpres+">");
		Element AnalSeqNode = (Element)the_DOC.createElement("seq");
		if(the_id!=null){
			AnalSeqNode.setAttribute("id",the_id);
		}
		if(the_length!=null){
			AnalSeqNode.setAttribute("length",the_length);
		}
		if(the_md5!=null){
			AnalSeqNode.setAttribute("md5checksum",the_md5);
		}
		if(the_name!=null){
			AnalSeqNode.appendChild(makeGenericNode(the_DOC,
					"name",the_name));
		}

		if((the_dbname!=null)&&(the_dbacc!=null)){
			System.out.println("DBXREF DBNAME<"+the_dbname
					+"> ACC<"+the_dbacc+">");
			AnalSeqNode.appendChild(makeGameDbxref(the_DOC,
					the_dbname,the_dbacc));
		}

		if(the_description!=null){
			AnalSeqNode.appendChild(makeGenericNode(the_DOC,
					"description",the_description));
		}
		if(the_residues!=null){
			AnalSeqNode.appendChild(makeGenericNode(the_DOC,
					"residues",
					formatResidues(the_residues)));
		}
		return AnalSeqNode;
	}

	/********/
	public Element makeCompAnalysisFromVec(Document the_DOC,Vector the_v){
		//Each feature with is_analysis = 1 is a comp_anal feature.
		//It is either a match, transposable_element, or an exon?
		Element compAnalNode = (Element)the_DOC.createElement(
				"computational_analysis");

		Feature the_ca = null;
		if(the_v.size()>0){
			the_ca = (Feature)the_v.get(0);
		}

		String resSpanType = "";
		//System.out.println("\tCOMP_ANAL PROGRAM<"+the_ca.getprogram()+">");
		if(the_ca.getprogram()!=null){
			compAnalNode.appendChild(makeGenericNode(the_DOC,
					"program",the_ca.getprogram()));
			resSpanType = the_ca.getprogram();
		}
		resSpanType += ":";

//TEMPORARY KLUDGE!!!!!!!!!!!!!!!!!!!!!!
		if((the_ca.getsourcename()==null)&&(the_ca.getprogram()!=null)){
			String prog = the_ca.getprogram();
			if((prog.startsWith("genscan"))
					||(prog.startsWith("piecegenie"))){
				the_ca.setsourcename("dummy");
			}
		}

		if(the_ca.getsourcename()!=null){
			//System.out.println("\tCOMP_ANAL SOURCENAME<"+
			//		the_ca.getsourcename()+">");
			compAnalNode.appendChild(makeGenericNode(the_DOC,
					"database",the_ca.getsourcename()));
			resSpanType += the_ca.getsourcename();
		}

		compAnalNode.appendChild(makeGameProperty(the_DOC,
				"qseq_type","genomic"));

		if((the_ca.getTypeId().equals("match"))
				||(the_ca.getTypeId().equals("mRNA"))
				||(the_ca.getTypeId().startsWith("transposable_element"))){
			String prog = the_ca.getprogram();
			//System.out.println("\tANALYSIS MATCH PROG<"+prog+">");
			if(prog==null){
				//System.out.println("COMP_ANAL PROGRAM IS NULL!!!");
			}else if(prog.startsWith("promotor")){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","Promotor Prediction"));
			}else if((prog.startsWith("transposon"))
					||(prog.startsWith("JOSH"))){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","Transposon"));
				resSpanType = "transposon";
			}else if((prog.startsWith("genscan"))
					||(prog.startsWith("piecegenie"))){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","Gene Prediction"));
			}else if((prog.startsWith("blastx"))){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","BLASTX Similarity to Fly"));
			}else{
				//System.out.println("\t\tSOME OTHER ANALYSIS TYPE<"+prog+">");
			}
			if(the_ca.gettimeexecuted()!=null){
				compAnalNode.appendChild(makeDateNode(the_DOC,
						the_ca.gettimeexecuted()));
			}

			for(int i=0;i<the_v.size();i++){
				Feature f = (Feature)the_v.get(i);
				Element resultSetNode = makeResultSetForMatch(
						the_DOC,f,resSpanType);
				//System.out.println("\tADDING RESULT_SET TO COMP_ANAL");
				compAnalNode.appendChild(resultSetNode);
			}
		}else{
			System.out.println("SHOULD NOT SEE THIS A<"
					+the_ca.getTypeId()+">");
		}
		return compAnalNode;
	}
	/***********/

	/********
	public Element makeCompAnalysis(Document the_DOC,Feature the_ca){
		//Each feature with is_analysis = 1 is a comp_anal feature.
		//It is either a match, transposable_element, or an exon?
		Element compAnalNode = (Element)the_DOC.createElement(
				"computational_analysis");

		String resSpanType = "";
		System.out.println("\tCOMP_ANAL PROGRAM<"+the_ca.getprogram()+">");
		if(the_ca.getprogram()!=null){
			compAnalNode.appendChild(makeGenericNode(the_DOC,
					"program",the_ca.getprogram()));
			resSpanType = the_ca.getprogram();
		}
		resSpanType += ":";

//TEMPORARY KLUDGE!!!!!!!!!!!!!!!!!!!!!!
		if((the_ca.getsourcename()==null)&&(the_ca.getprogram()!=null)){
			String prog = the_ca.getprogram();
			if((prog.startsWith("genscan"))
					||(prog.startsWith("piecegenie"))){
				the_ca.setsourcename("dummy");
			}
		}

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
		//System.out.println("\tRESSPANTYPE<"+resSpanType+">");

		compAnalNode.appendChild(makeGameProperty(the_DOC,
				"qseq_type","genomic"));

		if((the_ca.getTypeId().equals("match"))
				||(the_ca.getTypeId().equals("mRNA"))){
			String prog = the_ca.getprogram();
			//System.out.println("\tANALYSIS MATCH PROG<"+prog+">");
			if(prog==null){
				//System.out.println("COMP_ANAL PROGRAM IS NULL!!!");
			}else if(prog.startsWith("promotor")){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","Promotor Prediction"));
			}else if((prog.startsWith("transposon"))
					||(prog.startsWith("JOSH"))){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","Transposon"));
			}else if((prog.startsWith("genscan"))
					||(prog.startsWith("piecegenie"))){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","Gene Prediction"));
			}else if((prog.startsWith("blastx"))){
				compAnalNode.appendChild(makeGameProperty(
						the_DOC,
						"type","BLASTX Similarity to Fly"));
			}else{
				//System.out.println("\t\tSOME OTHER ANALYSIS TYPE<"+prog+">");
			}

			if(the_ca.gettimelastmodified()!=null){
				compAnalNode.appendChild(makeDateNode(the_DOC,
						the_ca.gettimelastmodified()));
			}

			Element resultSetNode = makeResultSetForMatch(
					the_DOC,the_ca,resSpanType);
			System.out.println("\tADDING RESULT_SET TO COMP_ANALYSIS");
			compAnalNode.appendChild(resultSetNode);
		}else{
			System.out.println("SHOULD NOT SEE THIS A");
		}
		return compAnalNode;
	}
	***********/

	public Element makeResultSetForMatch(Document the_DOC,
			Feature the_ca,String the_resSpanType){
		//System.out.println("\tMAKING RESULT_SET FOR MATCH RES_SPAN_TYPE<"
		//		+the_resSpanType+">");
		Element resultSetNode = (Element)the_DOC.createElement(
				"result_set");

//PREAMBLE
		if(the_ca.getUniqueName()!=null){
			resultSetNode.setAttribute("id",the_ca.getUniqueName());
		}

		//System.out.println("\tRESULT_SET PROGRAM<"+the_ca.getprogram()
		//		+"> ID<"+the_ca.getId()+">");
		if(the_ca.getFeatLoc()!=null){
			Span sp = the_ca.getFeatLoc().getSpan();
			Span retsp = sp.retreat(m_NewREFSPAN.getStart()-1);
			//System.out.println("HAS ITS OWN SPAN RET<"+retsp+"> ORIG <"+sp+">");
		}else{
			//System.out.println("HAS ITS OWN SPAN<NULL>");
		}

		if(the_ca.getName()!=null){
			//System.out.println("\tRESULT_SET NAME<"+the_ca.getName()+">");
			resultSetNode.appendChild(makeGenericNode(the_DOC,
					"name",the_ca.getName()));
		}
		//System.out.println("\tRESULT_SET UNIQUENAME<"+the_ca.getUniqueName()+">");


//BUILD SPAN LIST
		Vector rSpanList = new Vector();
		//System.out.println("\t\tPREEMPTIVE LOOK AT ALL RESULT_SPANS");
		for(int i=0;i<the_ca.getGenFeatCount();i++){
			//EACH ONE OF THESE IS A RESULT_SPAN CORRESPONDING
			//TO A FEATURE_RELATIONSHIP IN CHADO
			GenFeat CAgf = (GenFeat)the_ca.getGenFeat(i);
			/*******
			if(CAgf.getFeatLoc()!=null){
				System.out.println("\t\t\tQUERY SEQ_REL<"
					+CAgf.getFeatLoc().getSpan()
					+"> STRAND<"+CAgf.getFeatLoc().getstrand()
					+">");
			}else{
				System.out.println("\t\t\tQUERY SEQ_REL<null>");
			}
			if(CAgf.getAltFeatLoc()!=null){
				System.out.println("\t\t\tSBJCT SEQ_REL<"
					+CAgf.getAltFeatLoc().getSpan()
					+"> STRAND<"+CAgf.getAltFeatLoc().getstrand()
					+">");
			}else{
				System.out.println("\t\t\tSBJCT SEQ_REL<null>");
			}
			*******/
			rSpanList.add(CAgf);
		}

//SORT SPAN LIST
		for(int i=0;i<rSpanList.size();i++){
			Feature cai = (Feature)rSpanList.get(i);
			if(cai.getFeatLoc()!=null){
			for(int j=(i+1);j<rSpanList.size();j++){
				Feature caj = (Feature)rSpanList.get(j);
				if(caj.getFeatLoc()!=null){
					if((cai.getFeatLoc()!=null)
							&&(cai.getFeatLoc().getSpan()!=null)
							&&(caj.getFeatLoc()!=null)
							&&(caj.getFeatLoc().getSpan()!=null)){
						int strandi = cai.getFeatLoc().getstrand();
						int strandj = caj.getFeatLoc().getstrand();
						if(caj.getFeatLoc().getSpan().precedes(
								cai.getFeatLoc().getSpan(),
								strandi,strandj)){
							caj = (Feature)rSpanList.set(j,cai);
							rSpanList.set(i,caj);
							cai = caj;
						}
					}else{
						System.out.println("SHOULD NOT SEE COMP_ANAL NULL SPAN");
					}
				}
			}
			}
		}

//ADJUST SPANS FOR INTERBASE CONVERSION
//CALCULATE TOTAL SPAN FOR RESULT_SET
		int strand = 1;
		int strandguess = 0;
		int altstrand = 1;
		int altstrandguess = 0;
		Span resultSetSpan = new Span(0,0,null);
		Span resultSetAltSpan = new Span(0,0,null);
		for(int i=0;i<rSpanList.size();i++){
			Feature ca = (Feature)rSpanList.get(i);
			if(ca!=null){
				if(ca.getFeatLoc()!=null){
					strand = ca.getFeatLoc().getstrand();
					if(strandguess==0){
						strandguess = strand;
					}
					String sfi = ca.getFeatLoc().getSrcFeatureId();
					Span sp = ca.getFeatLoc().getSpan();
					//INTERBASE CONVERSION
					sp = new Span(sp.getStart()+1,sp.getEnd(),sp.getSrc());
					ca.getFeatLoc().setSpan(sp);
					resultSetSpan.grow(sp);
				}else{
					//System.out.println("MISSING FEATLOC!!!");
				}
				if(ca.getAltFeatLoc()!=null){
					altstrand = ca.getAltFeatLoc().getstrand();
					if(altstrandguess==0){
						altstrandguess = altstrand;
					}
					Span altsp = ca.getAltFeatLoc().getSpan();
					//INTERBASE CONVERSION
					if(altsp!=null){
						altsp = new Span(altsp.getStart()+1,
								altsp.getEnd(),
								altsp.getSrc());
						resultSetAltSpan.grow(altsp);
					}

				}else{
					//System.out.println("MISSING ALT FEATLOC!!!");
				}
			}
		}
		//System.out.println("\t\tRESULT_SET GROWN SPAN<"
		//		+resultSetSpan.toString()+">");
		//System.out.println("\t\tRESULT_SET GROWN ALTSPAN<"
		//		+resultSetAltSpan.toString()+">");

//RETREAT RESULT_SET SPAN AS APPROPRIATE FOR DIFFERENT ANALYSES TYPES
		//System.out.println("\tMAKING RESULT_SET FOR PROGRAM TYPE<"+the_ca.getprogram()+">");

//WRITE A RESULT_SET LEVEL SEQ_REL IF THERE ARE MULTIPLE RESULT_SPANs, 
		//ONLY ADD A SEQ_REL WHEN THERE ARE MULTIPLE RESULT_SPANS
		//THE SEQ IS THE SAME AS THE QUERY STRING
		//System.out.println("RESSPANSIZE<"+rSpanList.size()+">");
		String prog = the_ca.getprogram();
		System.out.println("PROGRAM<"+prog+"> FOR RESULT_SET LEVEL SPAN?");
//FSS
		if((prog!=null)&&((prog.startsWith("genscan"))
				||(prog.startsWith("piecegenie"))
				||(prog.startsWith("sim4"))
				||(prog.startsWith("tblastx"))
				||(prog.startsWith("blastx")))){
			System.out.println("\tYES");
			//DETERMINE WHETHER TO WRITE A SEQ_REL FOR THE RESULT_SET LEVEL
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

				Span rsspan = null;
				String qname = null;
				int strnd = 1;
				String siz = "";
				if((prog.startsWith("genscan"))
						||(prog.startsWith("piecegenie"))
						||(prog.startsWith("gap"))
						||(prog.startsWith("promoter"))
						){
					rsspan = resultSetSpan.retreat(
							(m_NewREFSPAN.getStart()-1));
					qname = queryName;
					strnd = strand;
					if(strnd==0){//KLUDGE FOR MISSING STRAND
						strnd = strandguess;
					}
					siz = "SINGLE";
				}else{
					rsspan = resultSetAltSpan.retreat(
							(m_NewREFSPAN.getStart()-1));
					qname = m_OldREFSTRING;
					strnd = altstrand;
					if(strnd==0){//KLUDGE FOR MISSING STRAND
						strnd = altstrandguess;
					}
					siz = "DUAL";
				}
				//System.out.println("CALCULATED RESULT_SET SPAN<"
				//		+rsspan.toString()
				//		+"> STRAND<"+strnd
				//		+"> CARD<"+siz+">");
				//System.out.println("GW: RESULT_SET ID<"
				//		+the_ca.getUniqueName()+">");
				//String featLocSrc = the_ca.getFeatLoc().getSpan().getSrc();
				//System.out.println("CMP1 FLS<"+featLocSrc
				//		+"> TO QNAME<"+qname+">");
				resultSetNode.appendChild(makeSeqRelNode(
						the_DOC,the_ca,rsspan,
						strnd,qname,"query",null));
			}else{
				//System.out.println("RSPANLISTSIZE<"
				//		+rSpanList.size()
				//		+"> SO DOESNT WARRANT A RESULT_SET LEVEL SPAN");
			}
		}

		for(int i=0;i<rSpanList.size();i++){
			Feature ca = (Feature)rSpanList.get(i);
			//System.out.println("WRITE SPAN LIST FOR<"+the_ca.getUniqueName()
			//		+">UNDER<"+ca.getUniqueName()+">");
			if((ca!=null)&&(ca.getFeatLoc()!=null)){
				if((the_ca.getUniqueName()!=null)
						&&(ca.getUniqueName()!=null)
						&&(!(the_ca.getUniqueName().equals(
						ca.getUniqueName())))){
					Element caresSpan = makeNewResultSpan(
							the_DOC,ca,
							the_resSpanType,
							ca.getrawscore());
					resultSetNode.appendChild(caresSpan);
				}else if((prog.startsWith("JOSH"))
						||(prog.startsWith("transposon"))){
					Element caresSpan = makeNewResultSpan(
							the_DOC,ca,
							"transposon",
							ca.getrawscore());
					resultSetNode.appendChild(caresSpan);
				}
			}
		}
		return resultSetNode;
	}

	public Element makeNewResultSpan(Document the_DOC,Feature the_ca,
			String the_typeId,String the_score){
		//System.out.println("RESULT_SPAN TYPE<"+the_typeId
		//		+"> ID<"+the_ca.getId()+"> UN<"
		//		+the_ca.getUniqueName()+">");
		Element resultSpanNode = (Element)the_DOC.createElement("result_span");

		if(the_ca.getId()!=null){
			resultSpanNode.setAttribute("id",the_ca.getId());
		}else if(the_ca.getUniqueName()!=null){
			String unm = the_ca.getUniqueName();
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

		//System.out.println("\tRESULT_SPAN SCORE <"+the_score+">");
		if(the_score!=null){
			resultSpanNode.appendChild(makeGenericNode(the_DOC,
					"score",the_score));
			resultSpanNode.appendChild(makeOutputNode(the_DOC,
					"score",the_score));
		}

		for(int i=0;i<the_ca.getGenFeatCount();i++){
			GenFeat gf = (GenFeat)the_ca.getGenFeat(i);
			
		}

//FSTART
/***************************/
//ITERATE THROUGH ITS 2 FEATLOCS
		String queryName = "";
		String queryResidues = "";
		String queryMd5 = "";
		String queryId = "";
		String queryseqlen = "";
		String subjResidues = "";

		for(int i=0;i<the_ca.getGenFeatCount();i++){
			GenFeat gf = (GenFeat)the_ca.getGenFeat(i);
			if(i==0){
				subjResidues = ((Feature)gf).getResidues();
			}else if(i==1){
				queryId = gf.getId();
				queryName = gf.getUniqueName();
				queryResidues = ((Feature)gf).getResidues();
				queryMd5 = ((Feature)gf).getMd5();
				queryseqlen = ((Feature)gf).getseqlen();
				if((queryName!=null)){
					//COLLECT DESCRIPTION FROM FEATUREPROP
					String queryDesc = null;
					for(int j=0;j<((Feature)gf).getFeatSubCount();j++){
						FeatSub fs = ((Feature)gf).getFeatSub(j);
						if((fs!=null)&&(fs instanceof FeatProp)){
							FeatProp fp = (FeatProp)fs;
							if(fp.getPkeyId().equals("description")){
								queryDesc = fp.getpval();
								break;
							}
						}
					}

					//COLLECT DBXREF
					String tmpdbname = null;
					String tmpacc = null;
					if(((Feature)gf).getDbxrefId()!=null){
						Dbxref d = ((Feature)gf).getDbxref();
						tmpdbname = d.getDBId();
						tmpacc = d.getaccession();
						//System.out.println("\tFOUND QUERY DBXREF DBNAME<"
						//		+tmpdbname+"> ACC<"+tmpacc+">");
					}

//DETERMINE IF THE SEQUENCE NEEDS TO BE PRINTED AS A SEPARATE SEQUENCE ENTITY
					if((queryDesc!=null)||(queryResidues!=null)
							||(tmpacc!=null)||(queryseqlen!=null)){
//System.out.println("LOOKHERE - NEED SEQUENCE CREATION FOR MORE THAN JUST piecegenie/genscan???");
						if((the_ca.getprogram()!=null)
								&&((the_ca.getprogram().startsWith("genscan"))
								||(the_ca.getprogram().startsWith("piecegenie")))){
						}else{
							String featLocSrc = the_ca.getFeatLoc().getSpan().getSrc();
							//System.out.println("CMP2 FLS<"+featLocSrc+"> TO QNAME<"+queryName+">");
							Element analSeq = makeAnalSeq(the_DOC,
									//queryName,queryseqlen,
									featLocSrc,queryseqlen,
									//queryMd5,queryName,
									queryMd5,featLocSrc,
									tmpdbname,tmpacc,
									queryDesc,queryResidues);
							//System.out.println("\tMADE ANAL_SEQ");
							//if(!(m_AnalSeqList.containsKey(queryName))){
							//	m_AnalSeqList.put(queryName,analSeq);
							if(!(m_AnalSeqList.containsKey(featLocSrc))){
								m_AnalSeqList.put(featLocSrc,analSeq);
							}
						}	
					}
				}else{
					System.out.println("\tNOT ENOUGH INFO TO MAKE SEQ");
				}
			}
		}

		//SUBJECT
		String prog = the_ca.getprogram();
		
		if(prog!=null){
			System.out.println("COMPARE PROGRAM<"+prog+">");
			int progType = 0;
			for(int i=0;i<m_CaSingleSpanList.size();i++){
				String sp = (String)m_CaSingleSpanList.get(i);
				if(prog.startsWith(sp)){
					progType = 1;
					System.out.println("\tSINGLE_SPAN");
					break;
				}
			}
			if(progType==0){
				for(int i=0;i<m_CaDoubleSpanList.size();i++){
					String dp = (String)m_CaDoubleSpanList.get(i);
					if(prog.startsWith(dp)){
						progType = 2;
						System.out.println("\tDOUBLE_SPAN");
						break;
					}
				}
			}
		if(progType==0){
			System.out.println("****UNKNOWN ANALYSIS PROGRAM TYPE!");
		}else if(progType==1){
		//}else if((prog.startsWith("transposon"))
		//		||(prog.startsWith("JOSH"))
		//		||(prog.startsWith("gap"))
		//		||(prog.startsWith("promoter"))
		//		||(prog.startsWith("genscan"))
		//		||(prog.startsWith("piecegenie"))
		//		||(prog.startsWith("trna"))
		//		||(prog.startsWith("tRNA"))
		//		){
			System.out.println("\t\tRESULT_SPAN SINGLE FEATLOC FOR<"
					+prog+">");
			String residues = subjResidues;
			if((prog.startsWith("JOSH"))
					||(prog.startsWith("gap"))
					){
				residues = queryResidues;
			}

			//GENIE AND GENSCAN
			Span gsSpan = the_ca.getFeatLoc().getSpan();
			gsSpan = gsSpan.retreat(m_NewREFSPAN.getStart()-1);
			the_ca.getFeatLoc().setSpan(gsSpan);
			if(the_ca.getFeatLoc()!=null){
				Span sp = the_ca.getFeatLoc().getSpan();
				String featLocSrc = the_ca.getFeatLoc().getSpan().getSrc();
				//System.out.println("XXX1<"+featLocSrc+">");
				int strand = the_ca.getFeatLoc().getstrand();
				resultSpanNode.appendChild(
						makeSeqRelNode(
						the_DOC,the_ca,
						sp,strand,
						featLocSrc,"query",
						residues));
				String FFFSTR = the_ca.getFeatLoc().getresidue_info();
				//System.out.println("RES<"+residues+"> CMP WITH<"+FFFSTR+">");
			}
		}else if(progType==2){
		//}else if((prog.startsWith("locator"))
		//		||(prog.startsWith("assembly"))
		//		||(prog.startsWith("clonelocator"))
		//		||(prog.startsWith("sim4"))
		//		||(prog.startsWith("repeatmasker"))
		//		||(prog.startsWith("tblastx"))
		//		||(prog.startsWith("groupest"))
		//		||(prog.startsWith("blastx"))
		//		||(prog.startsWith("pinsertion"))
		//	){
			//DUAL FEATLOC

			System.out.println("\t\tRESULT_SPAN DUAL FEATLOC FOR<"
					+prog+">");
			if(the_ca.getAltFeatLoc()!=null){
				Span sp = the_ca.getAltFeatLoc().getSpan();
				sp = sp.retreat(m_NewREFSPAN.getStart()-1);
				//INTERBASE CONVERSION
				sp = new Span(sp.getStart()+1,
						sp.getEnd(),
						sp.getSrc());
				int strand = the_ca.getAltFeatLoc().getstrand();
				String featLocSrc = the_ca.getAltFeatLoc().getSpan().getSrc();
				String residues = the_ca.getAltFeatLoc().getresidue_info();
				//System.out.println("XXX2<"+featLocSrc
				//		+"> OLDREFSTR<"+m_OldREFSTRING+">");
				resultSpanNode.appendChild(makeSeqRelNode(
						the_DOC,the_ca,
						sp,strand,
						//m_OldREFSTRING,"query",
						featLocSrc,"query",
						residues));
				//System.out.println("AFL QUERYNAME2<"+m_OldREFSTRING+">");
			}
			
			if(the_ca.getFeatLoc()!=null){
				Span sp = the_ca.getFeatLoc().getSpan();
				//ROLLBACK FOR CERTAIN ANALYSES
				if((prog.startsWith("pinsertion"))
					||(prog.startsWith("sim4"))
					||(prog.startsWith("blastx"))
					||(prog.startsWith("tblastx"))
					||(prog.startsWith("repeatmasker"))
					||(prog.startsWith("locator"))
						){//DONTROLLBACK
					//System.out.println("NOT ROLLING BACK subject");
				}else{
					//System.out.println("ROLLING BACK subject");
					sp = sp.retreat((m_NewREFSPAN.getStart()-1));
				}
				//GET SUBSECTION OF MAIN SEQUENCE INSTEAD
//RESIDUECHANGE
				int strand = the_ca.getFeatLoc().getstrand();
				String featLocSrc = the_ca.getFeatLoc().getSpan().getSrc();
				String residues = the_ca.getFeatLoc().getresidue_info();
				resultSpanNode.appendChild(makeSeqRelNode(
						the_DOC,the_ca,
						sp,strand,
						featLocSrc,"subject",
						residues));
			}
		}else{
			System.out.println("\t\tRESULT_SPAN UNKNOWN PROGRAM TYPE<"+prog+">");
		}
		}

/***************************/
//FEND
		//System.out.println("\t\tDONE RESULT_SPAN");
		return resultSpanNode;
	}

	public Element makeOutputNode(Document the_DOC,
			String the_type,String the_value){
		Element outputNode = (Element)the_DOC.createElement("output");
		outputNode.appendChild(makeGenericNode(the_DOC,"type",the_type));
		outputNode.appendChild(makeGenericNode(the_DOC,"value",the_value));
		return outputNode;
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
		//System.out.println("CONVERTING COMP_ANAL TYPE<"
		//		+the_typeId+"> TO<"+res+">");
		//res = "alignment";
		if(res==null){
			res = "alignment";
		}
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
		//System.out.println("KEY ID<"+pkeyIdTxt+"> VAL<"+pvalTxt+">");
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

	public String textReplace(String the_str,String the_old,
			String the_new){
		if((the_str==null)||(the_old==null)||(the_new==null)){
			return null;
		}
		int indx = the_str.lastIndexOf(the_old);
		if(indx>=0){
			String firstPart = the_str.substring(0,indx);
			String lastPart = the_str.substring(indx+the_old.length());
			return firstPart+the_new+lastPart;
		}
		return the_str;
	}
}



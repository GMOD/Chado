//ChadoWriter
package conv.gametochadx;
import java.io.*;
//import conv.util.*;

//JAVA4 HAS an XML parser built in, and it works differently than the
//one used with JAVA3
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

public static int SEQOMIT = 0;
public static int SEQINCL = 1;
public static int TPINCL = 0;
public static int TPOMIT = 1;
public static int REL4 = 1;
public static int HET = 1;

private String m_NewREFSTRING = "";
private String m_OldREFSTRING = null;
private Span m_REFSPAN = new Span(0,0);
private String m_RESIDUES = null;

private String m_InFile = null;
private String m_InFileName = null;
private String m_OutFile = null;
private int m_parseflags = GameSaxReader.PARSEALL;
private int m_modeflags = WRITEALL;
private int m_seqflags = 0;
private int m_tpflags = TPOMIT;
private int m_ulflags = 0;

//FOR BUILDING PREAMBLE
private HashSet m_CVList;
private HashSet m_CVTERMList;
private HashSet m_PUBList;
private HashSet m_EXONList;
private HashSet m_DBList;

private int m_ExonCount = 0;
private Vector m_ExonList = null;
private Vector m_RenExonList = null;
private String m_ExonGeneName = null;
private Vector m_TranUNList = null;
private Vector m_ProtUNList = null;

private HashMap m_SeqMap = new HashMap();
private HashMap m_SeqDescMap = new HashMap();

private int m_resinf = 0;

private GenFeat m_TopNode = null;

private boolean m_isHet = false;

	public ChadoWriter(String the_infile,String the_outfile,
			int the_parseflags,int the_modeflags,
			int the_seqflags,int the_tpflags,int the_ulflags){
		m_parseflags = the_parseflags;
		m_modeflags = the_modeflags;
		m_seqflags = the_seqflags;
		m_tpflags = the_tpflags;
		m_ulflags = the_ulflags;
		if(m_ulflags==HET){
			m_isHet = true;
		}
		if(the_infile==null){
			//System.out.println("NO INPUT FILE");
			System.exit(0);
		}
		m_InFile = the_infile;
		int indx = m_InFile.lastIndexOf("/");
		if(indx>0){
			m_InFileName = m_InFile.substring(indx+1);
		}
		m_OutFile = the_outfile;
		if(m_OutFile!=null){
			//OMIT OUTPUT FILE IN COMMAND LINE IN ORDER TO
			//FIND OUT WHICH GAME VERSION PRODUCED THE INPUT FILE
			String ver = GameVersionReader.getVerString(m_InFile);
			//System.out.println("\nFILE<"+m_InFileName+"> VER<"+ver+">");
			System.out.println("\n************************************");
			System.out.println("START G->C\n\t\tINFILE<"+m_InFile
					+">\n\t\tOUTFILE<"+m_OutFile
					+">\n\t\tFLAG<"+m_parseflags+">\n");
		}
	}

	public void GameToChado(){
		//READ GAME FILE
		GameSaxReader gsr = new GameSaxReader();
		gsr.parse(m_InFile,m_parseflags);
		GenFeat TopNode = gsr.getTopNode();
		m_TopNode = TopNode;
		//System.out.println("DONE PARSING GAME FILE");
		//WRITE CHADO FILE
		writeFile(TopNode,m_OutFile);
		//TopNode.Display(0);
		if(m_OutFile!=null){
			System.out.println("DONE G->C INFILE<"+m_InFile
					+"> OUTFILE<"+m_OutFile+">\n\n");
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
			Document m_DOC = impl.createDocument(null,"chado",null);
			Element root = makeChadoDoc(m_DOC,gf);

			DOMSource domSource = new DOMSource(m_DOC);
			StreamResult streamResult = null;
			if(the_filePathName!=null){
				streamResult = new StreamResult(new FileWriter(the_filePathName));
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
			m_DOC.appendChild(makeChadoDoc(m_DOC,gf));
			Writer out = new OutputStreamWriter(new FileOutputStream(the_filePathName,false));
			m_DOC.write(out);
			out.flush();
			**************/
		}catch(Exception ex){
			ex.printStackTrace();
		}
	}

	//TOP NODE
	public Element makeChadoDoc(Document the_DOC,GenFeat the_TopNode){
		Element root = the_DOC.getDocumentElement();

		//PREAMBLE
		//SOME OF THE CVTERMS ARE HARDCODED
		storeCV("chromosome_arm","SO");
		storeCV("Gadfly","SO");
		storeCV("gene","SO");
		storeCV("mRNA","SO");
		storeCV("exon","SO");
		storeCV("tRNA","SO");
		storeCV("match","SO");
		storeCV("protein","SO");
		storeCV("start_codon","SO");
		storePUB("Gadfly","curator");
		storeCV("computer file","pub type");
		storeCV("partof","relationship type");
		storeCV("producedby","relationship type");
		storeCV("transposable_element","SO");
		storeCV("element","SO");
		storeCV("description","property type");


/*********************************/
//TRANSACTION HANDLING START
		//CHANGED AND DELETED FEATURES
		Vector chngdGeneList = new Vector();
		Vector delGeneList = new Vector();
		Vector chngdTranList = new Vector();
		Vector delTranList = new Vector();

		boolean hasTransaction = false;
		if(m_modeflags==WRITECHANGED){
			//HANDLE changed_gene,deleted_gene,deleted_transcript
			//SORT THEM OUT AND SAVE FOR CREATION LATER
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				GenFeat gf = the_TopNode.getGenFeat(i);
				if(gf instanceof ModFeat){
					if(gf.getType().startsWith("changed_gene")){
						chngdGeneList.add(gf);
					}else if(gf.getType().startsWith("deleted_gene")){
						delGeneList.add(gf);
					}else if(gf.getType().startsWith("deleted_transcript")){
						delTranList.add(gf);
					}else{
						System.out.println("PROBLEM - WHAT COULD THIS BE???");
					}
				}else if(gf instanceof NewModFeat){
					System.out.println("*************");
					NewModFeat nmf = ((NewModFeat)gf);
					System.out.println("ChadoWriter - NEW TRANSACTION");
					String objClass = nmf.getObjClass();
					String operation = nmf.getOperation();
					if((operation==null)||(objClass==null)){
						System.out.println("INCOMPLETE TRANSACTION RECORD");
					//ADD
					}else if(operation.equalsIgnoreCase("ADD")){
						System.out.println("ADD");
						String BeforeAnnotId = nmf.getBeforeAnnotationId();
						String BeforeTransName = nmf.getBeforeTranscriptName();
						String AfterName = nmf.getAfterName();
						if(objClass.equalsIgnoreCase("ANNOTATION")){
							System.out.println("\tANNOTATION");
							chngdGeneList.add(new GenFeat(BeforeAnnotId));
						}else if(objClass.equalsIgnoreCase("TRANSCRIPT")){
							System.out.println("\tTRANSCRIPT");
							chngdGeneList.add(new GenFeat(BeforeAnnotId));
							chngdTranList.add(new GenFeat(BeforeTransName));
							System.out.println("\tADD TRANSCRIPT <"+AfterName
								+"> TO GENE ID<"+BeforeAnnotId+">");
					
						}else if(objClass.equalsIgnoreCase("EXON")){
							System.out.println("\tEXON");
						}else if(objClass.equalsIgnoreCase("TRANSLATION")){
							System.out.println("\tTRANSLATION");
						}else if(objClass.equalsIgnoreCase("EVIDENCE")){
							System.out.println("\tEVIDENCE");
						}else if(objClass.equalsIgnoreCase("COMMENT")){
							System.out.println("\tCOMMENT");
						}else{
							System.out.println("\tUNKNOWN OBJ_CLASS<"+objClass+">");
						}
					//DELETE
					}else if(operation.equalsIgnoreCase("DELETE")){
						System.out.println("DELETE");
						//ANNOTATION - deleted gene
						//TRANSCRIPT - deleted transcript
						//EXON - mark transcript as changed
						String BeforeId1 = nmf.getBeforeId1();
						String BeforeName = nmf.getBeforeName();
						String BeforeAnnotId = nmf.getBeforeAnnotationId();
						String BeforeTransName = nmf.getBeforeTranscriptName();
						if(objClass.equalsIgnoreCase("ANNOTATION")){
							System.out.println("\tANNOTATION");
							System.out.println("\tMARK ANNOT ID<"+BeforeId1
									+"> Name<"+BeforeName
									+"> AS DELETED");
							delGeneList.add(new GenFeat(BeforeId1));
						}else if(objClass.equalsIgnoreCase("TRANSCRIPT")){
							System.out.println("\tTRANSCRIPT");
							System.out.println("\tMARK TRANS Name<"
								+BeforeName
								+"> FROM ANNOT ID<"+BeforeAnnotId
									+"> AS DELETED");
							delTranList.add(new GenFeat(BeforeName));
						}else if(objClass.equalsIgnoreCase("EXON")){
							System.out.println("\tEXON");
							System.out.println("\tMARK TRANS <"
								+BeforeTransName+"> IN ANNOT ID<"
								+BeforeAnnotId
								+"> AS CHANGED");
							chngdTranList.add(new GenFeat(BeforeTransName));
						}else{
							System.out.println("\tUNKNOWN OBJ_CLASS<"+objClass+">");
						}
					//LIMITS
					}else if(operation.equalsIgnoreCase("LIMITS")){
						System.out.println("LIMITS");
						if(objClass.equalsIgnoreCase("ANNOTATION")){
							System.out.println("\tANNOTATION");
						}else if(objClass.equalsIgnoreCase("TRANSCRIPT")){
							System.out.println("\tTRANSCRIPT");
						}else if(objClass.equalsIgnoreCase("TRANSLATION")){
							System.out.println("\tTRANSLATION");
						}else if(objClass.equalsIgnoreCase("EXON")){
							System.out.println("\tEXON");
						}else{
							System.out.println("\tUNKNOWN OBJ_CLASS<"+objClass+">");
						}
					//STATUS
					}else if(operation.equalsIgnoreCase("STATUS")){
					//REDRAW
					}else if(operation.equalsIgnoreCase("REDRAW")){
					//SYNC
					}else if(operation.equalsIgnoreCase("SYNC")){
					//NAME
					}else if(operation.equalsIgnoreCase("NAME")){
					//ID
					}else if(operation.equalsIgnoreCase("ID")){
					//SPLIT
					}else if(operation.equalsIgnoreCase("SPLIT")){
						System.out.println("SPLIT");
						//ANNOTATION
						//	- DELETE both before_id
						//	- MARK after_ids as new/changed
						String BeforeId1 = nmf.getBeforeId1();
						String AfterId1 = nmf.getAfterId1();
						String AfterId2 = nmf.getAfterId2();
						if(objClass.equalsIgnoreCase("ANNOTATION")){
							System.out.println("\tANNOTATION<"
								+BeforeId1+"> DELETED");
							System.out.println("\tANNOT<"+AfterId1
								+"> AND<"+AfterId2
								+"> AS NEW/CHANGED");
							delGeneList.add(new GenFeat(BeforeId1));
							chngdGeneList.add(new GenFeat(AfterId1));
							chngdGeneList.add(new GenFeat(AfterId2));
						}else if(objClass.equalsIgnoreCase("TRANSCRIPT")){
							System.out.println("\tTRANS-SHOULDNT SEE THIS");
						}else if(objClass.equalsIgnoreCase("EXON")){
							System.out.println("\tEXON-SHOULDNT SEE THIS");
						}else{
							System.out.println("\tUNKNOWN OBJ_CLASS<"+objClass+">");
						}
					//MERGE
					}else if(operation.equalsIgnoreCase("MERGE")){
						System.out.println("MERGE");
						//ANNOTATION
						//	- DELETE both before_ids
						//	- MARK after as new/changed
						String BeforeId1 = nmf.getBeforeId1();
						String BeforeId2 = nmf.getBeforeId2();
						String AfterId1 = nmf.getAfterId1();
						if(objClass.equalsIgnoreCase("ANNOTATION")){
							System.out.println("\tANNOTATION <"+BeforeId1
								+"> AND<"+BeforeId2+"> DELETED");
							System.out.println("\tANNOTATION <"
								+AfterId1+"> AS NEW/CHANGED");
							delGeneList.add(new GenFeat(BeforeId1));
							delGeneList.add(new GenFeat(BeforeId2));
							chngdGeneList.add(new GenFeat(AfterId1));
						}else if(objClass.equalsIgnoreCase("TRANSCRIPT")){
							System.out.println("\tTRANSCRIPT-SHOULDNT SEE THIS");
						}else if(objClass.equalsIgnoreCase("EXON")){
							System.out.println("\tEXON-SHOULDNT SEE THIS");
						}else{
							System.out.println("\tUNKNOWN OBJ_CLASS<"+objClass+">");
						}
					//REPLACE
					}else if(operation.equalsIgnoreCase("REPLACE")){
						System.out.println("REPLACE");
						//ANNOTATION
						//TRANSCRIPT
						//EXON 
						if(objClass.equalsIgnoreCase("ANNOTATION")){
							System.out.println("\tANNOTATION");
						}else if(objClass.equalsIgnoreCase("TRANSCRIPT")){
							System.out.println("\tTRANSCRIPT");
						}else if(objClass.equalsIgnoreCase("EXON")){
							System.out.println("\tEXON");
						}else{
							System.out.println("\tUNKNOWN OBJ_CLASS<"+objClass+">");
						}
					}else{
						System.out.println("UNIDENTIFIED TRANSACTION OPERATION<"+operation+"> OBJ_CLASS<"+objClass+">");
					}
					System.out.println("");
					//nmf.Display();
				}
			}

			//PROCESS LIST TO REMOVE INSERTS/DELETES IN SAME FILE
			//CHECK THE 'CHANGED' LIST TO SEE IF IT WAS
			//SUBSEQUENTLY DELETED IN THIS SAME FILE, IN WHICH
			//CASE UNMARK THE CHANGED GENE AS CHANGED
			GenFeat delF=null,chngdF=null;
			if(delGeneList.size()>0){
				hasTransaction = true;
			}
			if(chngdGeneList.size()>0){
				hasTransaction = true;
			}
			if(delTranList.size()>0){
				hasTransaction = true;
			}
			if(chngdTranList.size()>0){
				hasTransaction = true;
			}
			for(int i=0;i<delGeneList.size();i++){
				delF = (GenFeat)delGeneList.get(i);
				for(int j=0;j<chngdGeneList.size();j++){
					chngdF = (GenFeat)chngdGeneList.get(j);
					if(delF.getId().equals(chngdF.getId())){
						chngdGeneList.remove(j);
					}
				}
			}

			//MARK ALL GENES WHICH HAVE BEEN LISTED AS CHANGED
			//AND GET ITS LIST OF NON ANNOT SEQUENCES
			//(FROM ITS 'produces_seq' TAG)
			//NEED TO MARK ALL NON ANNOT SEQUENCES WHICH ARE
			//IN THE ABOVE prodSeqList VECTOR, KEEP THESE
			//AND THROW AWAY THE REST
			Vector prodSeqList = new Vector();
			for(int i=0;i<chngdGeneList.size();i++){
				GenFeat gf = (GenFeat)chngdGeneList.get(i);
				//System.out.println("CHANGED GENE<"+gf.getId()+">");
				prodSeqList.addAll(markGeneAsChanged(
						the_TopNode,gf.getId(),
						delTranList));
			}
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				GenFeat gf = the_TopNode.getGenFeat(i);
				if(gf instanceof Seq){
					if(prodSeqList.contains(gf.getId())){
						//System.out.println("NEEDED SEQ<"+gf.getId()+">");
						gf.setChanged(true);
					}
				}
			}

			//SEE IF ANY DELETED TRANSCRIPTS ARE IN ANY
			//OF THE CHANGED GENES
			for(int i=0;i<chngdGeneList.size();i++){
				GenFeat gf = (GenFeat)chngdGeneList.get(i);
				String geneId = gf.getId();
				//System.out.println("CHANGED GENE<"+geneId+">");
				if((geneId!=null)&&(geneId.indexOf("temp")<0)){
					for(int j=0;j<delTranList.size();j++){
						GenFeat gft = (GenFeat)delTranList.get(j);
						String transId = gft.getId();
						if((transId!=null)&&(transId.startsWith(geneId))){
							delTransFromGene(the_TopNode,transId,geneId);
							//System.out.println("\tDELETED TRANS<"+transId+"> FROM INSIDE GENE<"+geneId+">");
						}
					}
				}
			}
		}

		if((m_modeflags==WRITECHANGED)&&(hasTransaction==false)){
			System.out.println("\tNO TRANSACTIONS");
			System.exit(0);
		}
//TRANSACTION HANDLING END
/****************************/

System.gc();
		//DO A PASS THROUGH THE WHOLE DATAMODEL, PICKING OUT
		//CVTERMS WHICH NEED TO BE DECLARED
		preprocessCVTerms(the_TopNode);

		//METADATA (map_position feature written below)
		if(the_TopNode.getArm()!=null){
			m_NewREFSTRING = the_TopNode.getArm();
			//if(m_NewREFSTRING!=null){
			//	m_NewREFSTRING = m_NewREFSTRING.toLowerCase();
			//}
			if(the_TopNode.getSpan()!=null){
				m_REFSPAN = the_TopNode.getSpan();
			}else{
				System.out.println("WARNING! USING DEFAULT FMIN,FMAX!\n");
				//m_REFSPAN = new Span(1,1);
				m_REFSPAN = new Span(0,0);
			}
		}
		System.out.println("WRITING CHADO REFSPAN<"+m_REFSPAN+">");

		//FIND NON ANNOT SEQ WITH FOCUS 'true' TO GET OLD REF STRING
		//String tmpResidues = null;
		m_RESIDUES = null;
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Seq){
				if((gf.getFocus()!=null)
						&&(gf.getFocus().equals("true"))){
					m_OldREFSTRING = gf.getId();
					//tmpResidues = gf.getResidues();
					m_RESIDUES = gf.getResidues();
				}
			}
		}

		if(m_NewREFSTRING!=null){
			int indx = m_NewREFSTRING.indexOf(".");
			if(indx>0){
				m_NewREFSTRING = m_NewREFSTRING.substring(0,indx);
			}
		}

		if(m_OldREFSTRING!=null){
			root.appendChild(makeAppdata(
					the_DOC,"title",m_OldREFSTRING));
			System.out.println("\tTITLE<"+m_OldREFSTRING+">");
		}
		if(m_OldREFSTRING!=null){
			root.appendChild(makeAppdata(
					the_DOC,"arm",m_NewREFSTRING));
			System.out.println("\tARM<"+m_NewREFSTRING+">");
		}
		if(m_REFSPAN!=null){
			root.appendChild(makeAppdata(
					the_DOC,"fmin",
					(""+(m_REFSPAN.getStart()-1))));
//					(""+(m_REFSPAN.getStart()))));
			System.out.println("\tFMIN<"+m_REFSPAN.getStart()+">");
			root.appendChild(makeAppdata(
					the_DOC,"fmax",
					(""+m_REFSPAN.getEnd())));
			System.out.println("\tFMAX<"+m_REFSPAN.getEnd()+">");
		}
		if(m_RESIDUES!=null){
			m_RESIDUES = cleanString(m_RESIDUES);
			root.appendChild(makeAppdata(
					the_DOC,"residues",m_RESIDUES));
			System.out.println("\tRESIDUE(len)<"+m_RESIDUES.length()+">");
		}

		root = makePreamble(the_DOC,root);

System.gc();
		//FIND THE REFERENCE SEQUENCE FROM THE GAME FILE
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Seq){
				if((gf.getFocus()!=null)
					&&(gf.getFocus().equals("true"))){
					//INSTEAD, WE SHOULD WRITE AN
					// _appdata FOR 'TITLE' and 'RESIDUES'
					m_OldREFSTRING = gf.getId();
				}
			}
		}

//ARM
	//REFERENCE FEATURE
		//ONLY ONE MAP_POSTION PER GAME FILE, REGARDLESS
		//OF HOW MANY ANNOTATIONS ARE THERE
		root.appendChild(makeArmNode(the_DOC,m_NewREFSTRING));

	//DELETE GENE FEATURES
		for(int i=0;i<delGeneList.size();i++){
			GenFeat gf = (GenFeat)delGeneList.get(i);
			if(gf.getId().indexOf(":temp")<=0){//NOT A 'TEMP'
				//System.out.println("MAKE DELETE FOR<"+gf.getId()+">");
				root.appendChild(makeDelFeat(the_DOC,gf));
			}
		}
	//DELETE TRANSCRIPT FEATURES
		for(int i=0;i<delTranList.size();i++){
			GenFeat gf = (GenFeat)delTranList.get(i);
			if(gf.getId().indexOf(":temp")<=0){//NOT A 'TEMP'
				//System.out.println("MAKE DELETE FOR<"
				//		+gf.getId()+">");
				root.appendChild(makeDelFeat(the_DOC,gf));
			}
		}

System.gc();

	//ANNOTATIONS, COMP_ANAL, AND NON ANNOT SEQUENCES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Annot){
				if((gf.isChanged())||(m_modeflags==WRITEALL)){
					if(isvalidIdTYPE(gf.getId())){
						Element anNode = makeAnnotNode(the_DOC,gf);
						if(anNode!=null){
							root.appendChild(anNode);
						}
					}
				}
			}else if(gf instanceof ComputationalAnalysis){
				if(m_OutFile!=null){
					//System.out.println("WRITING COMP_ANALYSIS<"+gf.getId()+">");
				}
				Vector analysisNodeList = makeAnalysisNode(the_DOC,gf);
				for(int j=0;j<analysisNodeList.size();j++){
					Element el = (Element)analysisNodeList.get(j);
					root.appendChild(el);
				}
			}else if((gf instanceof Seq)){//&&(m_seqflags==SEQINCL)){
				//IGNORE
				String seqid = ((Seq)gf).getId();
				String seqres = ((Seq)gf).getResidues();
				m_SeqMap.put(seqid,seqres);
				String seqdes = ((Seq)gf).getDescription();
				m_SeqDescMap.put(seqid,seqdes);
			}else if(gf instanceof ModFeat){
				//DONE EARLIER
			}else if(gf instanceof NewModFeat){
				//DONE EARLIER
			}else{
				if(m_OutFile!=null){
					System.out.println("PROBLEM - SOME UNKNOWN FEAT TYPE<"+gf.getId()+">\n");
				}
			}
System.gc();
		}
System.gc();
		return root;
	}

	public void delTransFromGene(GenFeat the_TopNode,
			String the_transId,String the_geneId){
		//System.out.println("START delTransFromGene");
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gene = the_TopNode.getGenFeat(i);
			if(gene instanceof Annot){
			//System.out.println("TESTING GENE<"+gene.getId()
			//		+"> TO SEE IF IT IS<"+the_geneId+">");
			if((gene.getId()!=null)
					&&(gene.getId().equals(the_geneId))){
					//System.out.println("\tTESTING <"
					//		+gene.getGenFeatCount()
					//		+"> TRANSCRIPTS");
				for(int j=0;j<gene.getGenFeatCount();j++){
					GenFeat tran = gene.getGenFeat(j);
					//System.out.println("\t\tTRANS ID<"
					//		+tran.getId()
					//		+"> NAME<"
					//		+tran.getName()
					//		+"> TO SEE IF IT IS<"
					//		+the_transId+">");
					if((tran.getId().equals(the_transId))								||((tran.getName()!=null)&&(tran.getName().equals(the_transId)))){
						//System.out.println("\t\t\tFOUND AND READY TO DELETE");
						gene.delGenFeat(j);
						return;
					}
				}
			}
			}
		}
		//System.out.println("END delTransFromGene");
	}

	public Vector markGeneAsChanged(GenFeat topNode,String the_id,
			Vector the_delTranList){
		//RETURNS A LIST OF ALL NON ANNOT SEQUENCES
		//	REFERENCED IN THIS GENE
		Vector prodSeqList = new Vector();
		for(int i=0;i<topNode.getGenFeatCount();i++){
			GenFeat gf = topNode.getGenFeat(i);
			if(gf.getType()!=null){
				//System.out.println("\tCHECKING GENE TYPE<"
				//		+gf.getType()+"> WITH ID<"
				//		+gf.getId()+">");
				if(gf.getId().equals(the_id)){
					//System.out.println("\t\tSETTING GENE<"
					//		+the_id+"> TO TRUE");
					gf.setChanged(true);
					prodSeqList = gf.getProducedSequenceList();
				}
				/*************/
				//IF THE ID IS FOR ONE OF ITS TRANSCRPTS
				for(int j=0;j<gf.getGenFeatCount();j++){
					GenFeat tgf = gf.getGenFeat(j);
					if((tgf.getId()!=null)&&(tgf.getId().equals(the_id))){
						tgf.setChanged(true);
						prodSeqList.addAll(tgf.getProducedSequenceList());
					}
				}
				/*************/
				//FIGURE OUT IF IT WAS A TRANSCRIPT DELETION
				//FOR A 'temp' TRANSCRIPT
				for(int j=0;j<the_delTranList.size();j++){
					GenFeat dt = (GenFeat)the_delTranList.get(j);
					if(dt.getId().indexOf(":temp")>0){
						//SEE IF THIS temp transcript
						//IS IN THIS GENE, IF SO MARK IT
						for(int k=0;k<gf.getGenFeatCount();k++){
							GenFeat gft = (GenFeat)gf.getGenFeat(k);
							if((gft.getId()!=null)&&(gft.getId().equals(dt.getId()))){
								
								gf.delGenFeat(k);
							}
						}
					}
				}
			}else{
				//System.out.println("\tCHECKING GENE <"
				//		+gf.getId()+"> WITH NULL TYPE");
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

		//ID
		RefFeatNode.setAttribute("id",the_ArmSTRING);

		//UNIQUENAME
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"uniquename",the_ArmSTRING));

		//ORGANISM_ID
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"organism_id","Dmel"));

		//TYPE_ID
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id","chromosome_arm"));
		return RefFeatNode;
	}

	public Element makeAnnotNode(Document the_DOC,GenFeat gf){
		//DONT PROCESS TE's FOR NOW
		System.out.println("MAKING ANNOT <"+gf.getId()+">");
		if((m_tpflags==ChadoWriter.TPOMIT)
				&&(gf.getId()!=null)
				&&(gf.getId().startsWith("TE"))){
			return null;
		}

		boolean changeTransForPseudo = false;
		if((gf.getType()!=null)&&(gf.getType().startsWith("pseudo"))){
			gf.setType("gene");
			changeTransForPseudo = true;
		}

		for(int i=0;i<gf.getGenFeatCount();i++){
			GenFeat tran = gf.getGenFeat(i);
			for(int j=0;j<gf.getGenFeatCount();j++){
				GenFeat tranj = gf.getGenFeat(j);
			}
		}

	//PREPROCESS THIS ANNOTATION
		//CALCULATE FEATLOC's FOR TRANSCRIPT AND GENES FROM EXONS
		//ALSO, CREATE A LIST OF ALL KNOWN EXON SPANS SO THAT THEY
		//CAN BE RENAMED TO BE IN ORDER AND REUSE THE SAME NAME FOR
		//THE SAME SPAN ACROSS ALL TRANSCRIPTS FOR A GIVEN GENE
		m_ExonList = new Vector();
		m_RenExonList = new Vector();
		m_TranUNList = new Vector();
		m_ProtUNList = new Vector();
		Span geneSpan = null;
		m_ExonGeneName = gf.getId();

		for(int i=0;i<gf.getGenFeatCount();i++){
			GenFeat tran = gf.getGenFeat(i);
			if(tran instanceof FeatureSet){
			/****/
			if(tran.getType()==null){
				tran.setType("mRNA");
			}
			if(changeTransForPseudo){
				tran.setType("pseudogene");
			}
			if((gf.getId()!=null)&&(!(gf.getId().startsWith("CR")))){
				tran.setType(convertTYPE(tran.getType()));
			}

			//System.out.println("+++NEW TRANSCRIPT ID<"+gf.getId()+">");
			if(((gf.getId()!=null)&&(gf.getId().startsWith("CR")))
					||(isvalidTransTYPE(tran.getType()))){
				/***********************/
				Span tranSpan = null;
				Span protSpan = null;
				for(int j=0;j<tran.getGenFeatCount();j++){
					GenFeat exon = tran.getGenFeat(j);
					if(exon instanceof FeatureSpan){
					/****/
					//COMPENSATE FOR MISSING/OLD EXON TYPES
					if(exon.getType()==null){
						exon.setType("exon");
					}else if(exon.getType().equals("start_codon")){
					}else if(exon.getType().equals("exon")){
					}else if(exon.getType().startsWith("translate")){
						exon.setType("start_codon");
					}else{//SOME ODD TYPE
						exon.setType("exon");
					}

					//CALCULATE THE SPANS AND BUILD
					//EXON LIST FOR ORDERING UPON PRINTING 
					if(exon.getType().startsWith("start_codon")){
						protSpan = exon.getSpan();
						Span tmpSpan = protSpan;
						if(!(gf.getId().startsWith("CR"))){
							protSpan = protSpan.advance(
								m_REFSPAN.getStart()-1);
						}
						//System.out.println(
						//	"\t\tSTART_CODON<"
						//	+exon.getId()
						//	+"> SP<"
						//	+tmpSpan.toString()
						//	+"> TO<"
						//	+protSpan.toString()+">");
						protSpan.setSrc(m_NewREFSTRING);
						exon.setSpan(protSpan);
					}else if(exon.getType().equals("exon")){
						Span exonSpan = exon.getSpan();
						Span tmpSpan = exonSpan;
						if(!(gf.getId().startsWith("CR"))){
							exonSpan = exonSpan.advance(
								m_REFSPAN.getStart()-1);
						}
						//System.out.println("\t\tEXON<"
						//	+exon.getId()
						//	+"> SP<"+tmpSpan
						//	+"> TO<"+exonSpan+">");
						exonSpan.setSrc(m_NewREFSTRING);
						exon.setSpan(exonSpan);

						String re = getRenExonName(exonSpan);
						if(re==null){
							//System.out.println("\t**STORING EXON<"+exon.getName()
							//		+"> AT SPAN<"+exonSpan.toString()+">");
							m_RenExonList.add(
								new RenEx(
								exon.getName(),
								exonSpan));
						}

						if(tranSpan==null){
							tranSpan=exonSpan;
						}else{
							tranSpan = tranSpan.union(exonSpan);
						}
						//System.out.println("AS ADVANCED EXON SPAN<"
						//		+exonSpan.toString()+">");
					}else{
						System.out.println("\tUNK FEATURE_SPAN TYPE<"
								+exon.getType()+">");
					}
					/****/
					}
				}
				if(tranSpan!=null){
					tranSpan.setSrc(m_NewREFSTRING);
					tran.setSpan(tranSpan);
					if(geneSpan==null){//FIRST TRANSCRIPT
						geneSpan = tranSpan;
					}else{//ADD SUBSEQUENT TRANS RANGES
						geneSpan = geneSpan.union(
								tranSpan);
					}
					//System.out.println("\tEND TRAN<"
					//		+tran.getId()+"> SP<"
					//		+tranSpan.toString()+">");
				}
				/***********************/
			}
			/****/
			}
		}
		if(geneSpan!=null){
			geneSpan.setSrc(m_NewREFSTRING);
		}
		gf.setSpan(geneSpan);

		for(int x=0;x<m_RenExonList.size();x++){
			RenEx rex = (RenEx)m_RenExonList.get(x);
			for(int y=0;y<m_RenExonList.size();y++){
				RenEx rey = (RenEx)m_RenExonList.get(y);
				if((x!=y)&&(rex.getName()!=null)
						&&(rey.getName()!=null)
						&&(rex.getName().equals(rey.getName()))){
					System.out.println("CONFLICT BETWEEN<"+rex+"> AND<"+rey+">");
				}
			}
		}

	//WRITE OUT THIS ANNOTATION
		Element GeneFeatNode = (Element)the_DOC.createElement("feature");
		//HEADER
		//System.out.println("EEEEE<"+gf.getId()+">");
		GeneFeatNode = makeFeatHeader(the_DOC,gf,GeneFeatNode,
				null,null,null);
		//ASPECT
		for(int j=0;j<gf.getGenFeatCount();j++){
			GenFeat agf = gf.getGenFeat(j);
			if(agf instanceof Aspect){
				//System.out.println("\tWRITING ASPECT");
				GeneFeatNode.appendChild(
					makeFeatCVTerm(the_DOC,(Aspect)agf));
			}
		}

		gf.setType(convertTYPE(gf.getType()));
		//System.out.println("\nSTART CHADO ANNOTATION TYPE<"
		//		+gf.getType()+">");
		if((gf.getType()!=null)&&(gf.getType().equals("remark"))){
			//IGNORE TRANSCRIPTS AND EXONS
			//System.out.println("REMARKS ONLY WRITTEN");
			return GeneFeatNode;
		}


		//System.out.println("START FILL_IN_BLANK_NAMES");
		fillInBlankNames(m_ExonGeneName);
		//System.out.println("END FILL_IN_BLANK_NAMES");

		//FEATURE_SET
		for(int j=0;j<gf.getGenFeatCount();j++){
			GenFeat fsgf = gf.getGenFeat(j);
			if(fsgf instanceof FeatureSet){
			if(((gf.getId()!=null)&&(gf.getId().startsWith("CR")))
					||(isvalidTransTYPE(fsgf.getType()))){
				m_ExonCount = 0;
				//System.out.println("\tSTART CHADO FEATURE_SET ID<"+gf.getId()
				//		+"> NAME<"+gf.getName()+">");
				GeneFeatNode.appendChild(
						makeFeatRel(the_DOC,"partof",0,
						makeFeatBodyNode(the_DOC,fsgf,
								null,
								gf.getType(),
								gf.getId())));
			}
			}
		}
		//System.out.println("DONE ANNOT NODE\n\n");
		//DisplayRenExon();
		return GeneFeatNode;
	}

	public Element makeSeqNode(Document the_DOC,
			GenFeat the_gf,Span firstSpan,
			String the_parentName,String the_parentId){
		String seqType = the_gf.getType();
		//System.out.println("MAKE_SEQ_NODE ID<"+the_gf.getId()
		//		+"> ParentName<"+the_parentName
		//		+"> ParentID<"+the_parentId+">");
		Element seqFeatNode = (Element)the_DOC.createElement("feature");

		//ATTRIBUTES
		String seqId = the_gf.getId();
		seqId = textReplace(seqId,".3","");
		String seqName = the_gf.getName();
		seqName = textReplace(seqName,".3","");

		if((seqId==null)||(seqId.startsWith("null"))){
			if((seqName==null)||(seqName.startsWith("null"))){
				seqId = textReplace(the_parentName,"-R","-P");
				seqName = seqId;
			}else{
				seqId = seqName;
			}
		}


		String parentBase = getBase(the_parentName);

		if((parentBase!=null)
				&&(seqId!=null)
				&&(seqId.startsWith(parentBase))){
			if(seqType.equals("aa")){
				seqId = textReplace(seqId,"-R","-P");
				textCheck(seqId);
			}
		}

		//System.out.println("FRANK_ID<"+seqId+">");

		//ID
		if(seqId!=null){
			int dashSeq = seqId.indexOf("_seq");
			if(dashSeq>0){
				seqId = seqId.substring(0,dashSeq);
			}
			seqFeatNode.setAttribute("id",seqId);
		}


		//NAME
		if(seqName!=null){
			if((seqType.equals("aa"))||(seqType.equals("protein"))){
				seqName = textReplace(seqName,"-R","-P");
				textCheck(seqName);
				//System.out.println("  SEQNAME1<"+seqName
				//		+"> PAR<"+the_parentName+">");
				if((the_parentName!=null)&&(seqName.indexOf("temp")>0)){
					seqName = textReplace(the_parentName,
							"-R","-P");
				}
			}
			String plainName = textReplace(the_parentName,"-R","-P");
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"name",plainName));
		}

		//CHECK FOR MULTIPLE PROTEINS WITH SAME UNIQUENAME
		if(seqName!=null){
			if((seqType.equals("aa"))||(seqType.equals("protein"))){
			//System.out.println("SAVING PROTEIN<"+seqName+">");
			for(int u=0;u<m_ProtUNList.size();u++){
				String oldun = (String)m_ProtUNList.get(u);
				if(oldun.equals(seqName)){
					System.out.println("ERROR: PROT UNIQUENAME<"
							+seqName+"> IS REPEATED");
				}
			}
			m_ProtUNList.add(seqName);
			}
		}


		//UNIQUENAME
		String uniquename = seqName;
		if(uniquename==null){
			uniquename = seqId;
		}

		if(uniquename==null){
			uniquename = "UNKNOWN";
		}
		if((seqType.equals("aa"))||(seqType.equals("protein"))){
			uniquename = textReplace(uniquename,"-R","-P");
			textCheck(uniquename);
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
		if(seqType!=null){
				seqFeatNode.appendChild(makeGenericNode(
						the_DOC,"type_id",
						convertTYPE(seqType)));
		}

		//SEQLEN
		if(the_gf.getResidueLength()!=null){
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"seqlen",the_gf.getResidueLength()));
		}else{
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"seqlen","0"));
		}

		//RESIDUES
		if(the_gf.getResidues()!=null){
			String tmpRes = cleanString(
					the_gf.getResidues());
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"residues",tmpRes));
		}

		//DBXREF_ID
		if((seqType!=null)&&((seqType.equals("gene"))
				||(isvalidTransTYPE(seqType)))){
			if(isvalidIdTYPE(the_gf.getId())){
				storeDB("Gadfly");
				seqFeatNode.appendChild(
						makeDbxrefIdAttrNode(
						the_DOC,"Gadfly",
						the_gf.getId()));
			}
		}

		//FEATURE_DBXREF
		//System.out.println("FEATURE_DBXREF");
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					seqFeatNode.appendChild(
						makeFeatureDbxrefAttrNode(
						the_DOC,attr));
				}
			}
		}

		//SPANS
		if(firstSpan!=null){
			seqFeatNode.appendChild(makeFeatureLoc(
					the_DOC,firstSpan,true));
		}
		//System.out.println("END NON_ANNOT_SEQ NODE\n");
		return seqFeatNode;
	}

	public String textReplace(String the_str,String the_old,
			String the_new){
		if((the_str==null)||(the_old==null)
				||(the_new==null)){
			return null;
		}
		int indx = the_str.lastIndexOf(the_old);
		if(indx>=0){
			String firstPart = the_str.substring(0,indx);
			String lastPart = the_str.substring(
					indx+the_old.length());
			return firstPart+the_new+lastPart;
		}
		return the_str;
	}

	public void textCheck(String the_str){
		if(the_str!=null){
			int resp = 0;
			int strlen = the_str.length();
			int indx = the_str.lastIndexOf("-R");
			if((indx>0)&&((indx+2)<strlen)){
				String suffix = the_str.substring(indx+2,indx+3);
				//System.out.println("SUFFIX<"+suffix+">");
				/********/
				try{
					resp = Integer.decode(suffix).intValue();
				}catch(Exception ex){
				}
				if(resp>0){
					System.out.println("WARNING: SUFFIX FOR <"
							+the_str+"> IS A NUMBER");
				}
				/********/
			}
			indx = the_str.lastIndexOf("-P");
			if((indx>0)&&((indx+2)<strlen)){
				String suffix = the_str.substring(indx+2,indx+3);
				//System.out.println("SUFFIX<"+suffix+">");
				/********/
				try{
					resp = Integer.decode(suffix).intValue();
				}catch(Exception ex){
				}
				if(resp>0){
					System.out.println("WARNING: SUFFIX FOR <"
							+the_str+"> IS A NUMBER");
				}
				/********/
			}
		}
	}

	public String baseName(String the_name){
		if(the_name==null){
			return null;
		}
		int indx = the_name.lastIndexOf("-R");
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
			modfeatNode.setAttribute("ref","Gadfly:"+the_gf.getId());
		}
		return modfeatNode;
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
						//break;//EXPECT THERE TO BE ONLY ONE
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
				the_DOC,"pub_id","gadfly3"));
		return featureCVTerm;
	}

	public Element makeFeatRel(Document the_DOC,
			String the_relType,int the_rank,Element the_el){
		//FEATURE_RELATIONSHIP WRAPPER
		Element featrel = (Element)the_DOC.createElement(
				"feature_relationship");
		if(the_rank>0){
			featrel.appendChild(makeGenericNode(
					the_DOC,"rank",(""+the_rank)));
		}
		featrel.appendChild(makeGenericNode(
				the_DOC,"type_id",the_relType));

		Element subjfeat = (Element)the_DOC.createElement("subject_id");
		subjfeat.appendChild(the_el);
		featrel.appendChild(subjfeat);
		return featrel;
	}

	public Element makeFeatBodyNode(Document the_DOC,GenFeat the_gf,
			String the_parentName,String the_parentType,
			String the_parentId){
		Element FeatNode = (Element)the_DOC.createElement("feature");
		Span startCodonSpan = null;
		String FSType = "";
		if((the_gf.getType()!=null)&&(the_gf.getType().equals("remark"))){
			//IGNORE EXONS AND PROTEINS OF THIS TRANSCRIPT
			System.out.println("REMARKS SHOW ONLY HEADER INFO, REST IGNORED");
			FeatNode = makeFeatHeader(the_DOC,the_gf,FeatNode,
					the_parentName,the_parentType,the_parentId);
			return FeatNode;
		}

		if(the_gf instanceof FeatureSet){
		//System.out.println("CREATING FEATURE_SET ID <"
		//		+the_gf.getId()+"> NAME<"+the_gf.getName()
		//		+">");
		Vector FSpanList = new Vector();
		//MAKE SURE THERE IS A CDNA
		boolean foundCdna = false;
		Span START_CODON = null;
		String cmpTo = "";
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			if(gf instanceof FeatureSpan){
				/********************/
				if(gf.getType()==null){
					System.out.println("NULLTYPE ID<"+gf.getId()+">");
					//NO TYPE GIVEN FOR SPAN - GUESS
					if(the_gf.getType().equals("transposable_element")){
						//PARENT IS TYPE 'TE'
						gf.setType(the_gf.getType());
					}else if((gf.getId()!=null)
						&&(gf.getId().startsWith("TE"))){
						//PARENT IS TYPE 'TE' BY NAME
						gf.setType("transposable_element");
					}else if(isvalidTransTYPE(the_gf.getType())){
						//PARENT IS transcript
						//EITHER exon OR start_codon
						if(gf.getSpan().getLength()==3){
							gf.setType("start_codon");
							System.out.println("BAD");
						}else{
							gf.setType("exon");
						}
					}else{
						gf.setType("exon");
					}
					System.out.println("\tISNOW<"+gf.getType()+">");
				}
				/********************/
				if(gf.getType().equals("start_codon")){
					START_CODON = gf.getSpan();
				}else if(gf.getType().equals("exon")){
					FSpanList.add(gf.getSpan());
				}
			}else if(gf instanceof Seq){
				/********************/
				if(gf.getType()==null){
					//GUESS AT TYPE
					if(gf.getResidues()!=null){
						String res = gf.getResidues().substring(0,1);
						//System.out.println("SAMPLERES<"
						//	+res+">");
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
				/********************/
				if(gf.getType().equals("cdna")){
					foundCdna = true;
					cmpTo = cleanString(gf.getResidues());
					//System.out.println("\tFOUND CDNA <"
					//		+gf.getId()+">");
				}
			}
		}

		//NO CDNA - FIND AT END
		if(foundCdna==false){
			System.out.println("\tDID NOT FIND CDNA FOR TRANSCRIPT NAME<"
					+the_gf.getName()+">");
			int seqcnt = 0;
			for(int i=0;i<m_TopNode.getGenFeatCount();i++){
				GenFeat seqgf = m_TopNode.getGenFeat(i);
				if(seqgf instanceof Seq){
					//System.out.println("FOUNDCDNA ID<"
					//		+seqgf.getId()+">");
					seqcnt++;
					//if(gf.getId()!=null){
					//}
				}
			}			
			System.out.println("SEARCHED THROUGH <"+seqcnt+">");
		}

		//STILL NO CDNA - MAKE ONE
		if(foundCdna==false){
			System.out.println("STILL NO CDNA FOR TRANSCRIPT NAME<"
					+the_gf.getName()+">");
			Seq fake = new Seq(the_gf.getId()+".3");
			fake.setType("cdna");
			String res = cleanString(m_RESIDUES);
			String spanRes = "";
			String totRes = "";
			for(int i=0;i<FSpanList.size();i++){
				Span sp = (Span)FSpanList.get(i);
				sp = sp.retreat(m_REFSPAN.getStart()-1);
				if(sp.getStart()<sp.getEnd()){
					spanRes = res.substring(
							sp.getStart()-1,
							sp.getEnd());
				}else{
					spanRes = res.substring(
							sp.getEnd()-1,
							sp.getStart());
					spanRes = SeqUtil.reverseComplement(spanRes);
				}
				totRes += spanRes;
			}
			fake.setResidues(totRes);
			fake.setMd5(MD5.convert(totRes));
			the_gf.setResidues(totRes);
			the_gf.addGenFeat(fake);
		}else{
			//System.out.println("FOUND CDNA FOR TRANSCRIPT<"
			//		+the_gf.getId()+">");
		}

		}//END IF FEATURE_SET



		FeatNode = makeFeatHeader(the_DOC,the_gf,FeatNode,
				the_parentName,the_parentType,the_parentId);

		String calcaaStr = null;
		Vector ExonList = new Vector();
		int newExonNum = 0;
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			if(gf instanceof FeatureSet){
				FeatNode.appendChild(
						makeFeatRel(the_DOC,"partof",0,
						makeFeatBodyNode(the_DOC,gf,
						the_gf.getName(),
						the_gf.getType(),
						the_gf.getId())));
			System.out.println("\n");
			}else if(gf instanceof FeatureSpan){
				if(gf.getType().equals("start_codon")){
					startCodonSpan = gf.getSpan();
					newExonNum = 0;
	
				}else if(gf.getType().equals("exon")){
					String newExonName = getRenExonName(
							gf.getSpan());
					//System.out.println("\t**FINDING EXON<"+newExonName
					//	+"> AT SPAN<"+gf.getSpan()
					//	+"> FOR ID<"+gf.getId()+">");
					newExonNum++;

					gf.setId(newExonName);
					gf.setName(newExonName);
					FeatNode.appendChild(
						makeFeatRel(the_DOC,"partof",
						newExonNum,
						makeFeatBodyNode(the_DOC,gf,
						the_gf.getName(),
						the_gf.getType(),
						the_gf.getId())));
					ExonList.add(gf.getSpan());
				}else{
					//NOMI APOLLO BUG
				}
			}else if(gf instanceof Seq){
				if(gf.getType().equals("cdna")){
					String cdnaStr = cleanString(
							gf.getResidues());
					//CALCULATE PROTEIN
					if((cdnaStr!=null)
						&&(the_gf.getType()!=null)
						&&(!(the_gf.getType().equals("snoRNA")))
						&&(!(the_gf.getType().equals("ncRNA")))
						&&(!(the_gf.getType().equals("snRNA")))
						&&(!(the_gf.getType().equals("tRNA")))
						&&(!(the_gf.getType().equals("rRNA")))
						&&(!(the_gf.getType().equals("pseudogene")))
						&&(!(the_gf.getType().equals("nuclear_micro_RNA_coding_gene")))
						&&(gf.getId()!=null)
						&&(!(gf.getId().startsWith("CR")))){
						/*********/
						if(m_isHet==false){
							//NON HETEROCHROMATIN
							int st = 0;
							if(startCodonSpan!=null){
								st = calcRelSCPos(
									startCodonSpan,
									ExonList);
								//System.out.println("TRANSCRIPT <"+the_gf.getId()+"> HAS A START CODON OF<"+startCodonSpan+"> AND CALC START<"+st+">");
							}else{
								st = -1;
							}
							if(st>=0){
								cdnaStr = cdnaStr.substring(st);
								Ribosome r = new Ribosome();
								calcaaStr = r.translate(cdnaStr,
									Ribosome.DEF_TRANS_TYPE);
							}
						}else{
							System.out.println("IS HETEROCHROMATIN");
							//FIND givenaaStr AND PUT
							//IN calcaaStr
							for(int j=0;j<the_gf.getGenFeatCount();j++){
								GenFeat ggf = the_gf.getGenFeat(j);
								if(ggf instanceof Seq){
									if(ggf.getType().equals("aa")){
										calcaaStr = cleanString(ggf.getResidues());
										break;
									}
								}
							}
						}
						/*********/
						if(calcaaStr!=null){
							GenFeat protGF = new GenFeat(null);
							protGF.setType("aa");
							protGF.setSpan(startCodonSpan);
							String protId = textReplace(gf.getId(),"-R","-P");
							//System.out.println("PROT_ID<"+protId+"> OLD<"+gf.getId()+">");
							textCheck(protId);
							protGF.setId(protId);
							protGF.setName(protId);
							calcaaStr = cleanProt(calcaaStr);
							calcaaStr = cleanString(calcaaStr);
							if(calcaaStr!=null){
								protGF.setResidues(calcaaStr);
								protGF.setResidueLength(""+calcaaStr.length());
								protGF.setMd5(MD5.convert(calcaaStr));
							}
							Span newSpan = ProtCalc.calcNewProtSpan(
									protGF.getSpan(),
									calcaaStr.length(),
									ExonList);
							newSpan.setSrc(m_NewREFSTRING);
							//System.out.println("\t\tPROT<"
							//		+newSpan.toString()
							//		+">");
							FeatNode.appendChild(
							makeFeatRel(the_DOC,"producedby",0,
								makeSeqNode(the_DOC,
									protGF,newSpan,
									the_gf.getName(),
									the_gf.getId())));
						}
					}else{
						System.out.println("PROTEIN NOT COMPUTED FOR <"+the_gf.getId()+"> StartCodon <"+startCodonSpan+"> FEATURE_SET TYPE<"+the_gf.getType()+">");
						if((the_gf.getType()!=null)&&(the_gf.getType().equals("mRNA"))){
							System.out.println("WARNING: SHOULD HAVE BEEN A PROTEIN COMPUTED");
						}
					}
				}else if(gf.getType().equals("aa")){
					String givenaaStr= cleanString(
							gf.getResidues());
					if(calcaaStr!=null){
						int cmp = calcaaStr.compareTo(givenaaStr);
						if(cmp!=0){
							System.out.println("\t\tWARNING - PROTCOMPARE IS NON ZERO<"+cmp+">");
							System.out.println("GIVEN<"
								+givenaaStr+">");
							System.out.println("CALCD<"
								+calcaaStr+">");
						}
					}
				}else{
					System.out.println("SHLDNTSEE UNKTYPE<"
							+gf.getType()+">");
				}
			}else{//COMP_ANAL/RESULT_SET/SPAN
				System.out.println("SHOULD NEVER SEE THIS??");
				FeatNode.appendChild((Element)
					the_DOC.createElement("analysis"));
			}
		}
		return FeatNode;
	}

	private String cleanProt(String the_prot){
		if(the_prot!=null){
			int indx = the_prot.indexOf("@");
			if(indx>0){
				the_prot = the_prot.substring(0,indx);
			}
		}
		return the_prot;
	}

	private boolean isForward(Vector the_spanList){
		boolean forw = true;
		if((the_spanList!=null)&&(the_spanList.size()>0)){
			Span ex = (Span)the_spanList.get(0);
			if(ex.getStart()>ex.getEnd()){
				forw = false;
			}
		}
		return forw;
	}

	private int calcRelSCPos(Span the_sc,Vector the_spanList){
		//System.out.print("CalcRelSCPos LOOKING FOR<"+the_sc.toString()+">");
		boolean isForward = true;
		//JUST FOR TEST OF LOCATION WITHIN AN EXON, THE SC IS MADE SMALLER
		Span scSpan = new Span(the_sc.getStart(),the_sc.getStart());
		if(the_sc.getStart()>the_sc.getEnd()){
			//REVERSE
			isForward = false;
		}
		int deductionLen = 0;
		if(isForward){
			//System.out.println("\tIS FORWARD");
			for(int i=0;i<the_spanList.size();i++){
				Span ex = (Span)the_spanList.get(i);
				//System.out.print("\tEXON SP<"+ex.toString()+">");
				if(ex.contains(scSpan)){
					//System.out.println(" CONTAINS <"
					//		+scSpan.toString()+">");
					deductionLen += (scSpan.getStart()-ex.getStart());
					return deductionLen;
				}else{
					//System.out.println(" HAS NO START CODON");
					deductionLen += ex.getLength();
				}
			}
		}else{
			//System.out.println("\tIS REVERSE");
			for(int i=0;i<the_spanList.size();i++){
				Span ex = (Span)the_spanList.get(i);
				//System.out.print("\tEXON SP<"+ex.toString()+">");
				if(ex.contains(scSpan)){
					//System.out.println("CONTAINS <"
					//		+scSpan.toString()+">");
					deductionLen += (-scSpan.getStart()+ex.getStart());
					return deductionLen;
				}else{
					//System.out.println("NO START CODON IN<"+ex.toString()+">");
					deductionLen += ex.getLength();
				}
			}
		}
		return deductionLen;
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
			String the_parentName,String the_parentType,
			String the_parentId){

		//System.out.println("FEAT HEADER FOR ID<"+the_gf.getId()+"> TYPE<"+the_gf.getType()+"> P_NAME<"+the_parentName+"> P_ID<"+the_parentId+"> P_TYPE<"+the_parentType+">");
		//UNIVERSAL HEADER (NAME, UNIQUENAME, FEATUREPROP,DBXREF,etc FOR
		//ALL FEATURES REPRESENTING ANNOTATION,FEATURE_SET,FEATURE_SPAN
		//ID PROCESSING
		String idTxt = the_gf.getId();
		if(idTxt!=null){
			//REMOVE SUFFIX FROM ID
			int dashSeq = idTxt.indexOf("_seq");
			if(dashSeq>0){
				idTxt = idTxt.substring(0,dashSeq);
			}
		}


		//PREPROCESS TYPE_ID
		String tmpTypeId = the_gf.getType();
		//System.out.println("GIVEN TYPE<"+tmpTypeId+">");
		if(tmpTypeId==null){
			//GUESS AT TYPE
			if(idTxt.indexOf("-R")>0){
				tmpTypeId = "mRNA";
			}else if(idTxt.indexOf(":")>0){
				tmpTypeId = "exon";
			}else if(the_gf instanceof FeatureSpan){
				tmpTypeId = "exon";
				the_gf.setType(tmpTypeId);
			}
		}
		//System.out.println("MOD1 TYPE<"+tmpTypeId+">");

		//SPECIAL FOR CR's WITH FEATURE_SETS of type 'transcript'
		String specialTypeId = null;
		if((the_gf instanceof Annot)
				&&(idTxt!=null)&&(idTxt.startsWith("CR"))){
			if(the_gf instanceof Annot){
				if(tmpTypeId.startsWith("miscell")){
					tmpTypeId = "remark";
				}else{
					specialTypeId = "gene";
				}
			}
		}

		if((the_gf instanceof FeatureSet)
				&&(tmpTypeId.equals("transcript"))){
			//System.out.println("FOUND FEATURE_SET <"+the_gf.getId()+"> IN<"+the_parentId+"> OF TYPE TRANSCRIPT");
			tmpTypeId = "mRNA";
			if(!the_parentType.equals("gene")){
				//PREEMPT THE REPRESENTATION OF THIS TRANSCRIPT
				//AS AN mRNA FOR THIS SPECIAL CASE
				specialTypeId = the_parentType;
			}
		}

		tmpTypeId = convertTYPE(tmpTypeId);

		//CORRECT FOR PROTEIN IDs HAVING A '-R'
		//PREFIX INSTEAD OF '-P'
		if(tmpTypeId.equals("aa")){
			if(idTxt.lastIndexOf("-R")>0){
				idTxt = textReplace(idTxt,"-R","-P");
				textCheck(idTxt);
			}
		}

		//MUNGE THE NAMES FOR start_codonS WHICH
		//ARE NOT UNIQUE IN GAME
		if(tmpTypeId.equals("start_codon")){
			idTxt = idTxt+"_start_codon";
		}

//UNIQUENAME PROCESSING
/***********************/
		//UNIQUENAME PROCESSING
		String uniquename = null;
		//UN = ID unless its a transcript with a 'temp' ID
		if(tmpTypeId.equals("remark")){
			uniquename = idTxt;
		}else if((the_gf instanceof Annot)
				&&(the_gf.getId()!=null)
				&&(the_gf.getId().startsWith("CR"))){
			uniquename = idTxt;
		}else if((the_gf instanceof FeatureSet)
				&&(the_parentId!=null)
				&&(the_parentId.startsWith("CR"))){
			if(idTxt!=null){
				uniquename = idTxt;
			}else{
				uniquename = the_parentId
						+getTranSuffix(the_gf.getName());
			}
		}else if(tmpTypeId.equals("exon")){
			m_ExonCount++;
			if(idTxt==null){
				idTxt = the_parentName+":temp"+m_ExonCount;
//HETADJUST
				if(m_isHet){
					uniquename = baseName(the_parentName)
							+":temp"+m_ExonCount;
				}else{
					uniquename = idTxt;
				}
			}else{
				uniquename = idTxt;
			}
			//System.out.println("UNIQUENAME<"+uniquename+">");
		}else if(tmpTypeId.equals("start_codon")){
			if(idTxt==null){
				uniquename = baseName(the_parentName)
						+"_start_codon";
			}else{
				uniquename = idTxt;
			}
		}else if(isvalidTransTYPE(tmpTypeId)){
			//System.out.println("FSS_TRANSCRIPT");
			if((idTxt!=null)&&(idTxt.indexOf("temp")<=0)){
				uniquename = the_parentId+getTranSuffix(idTxt);
			}else{
				uniquename = the_parentId
						+getTranSuffix(the_gf.getName());
			}
		}else if(tmpTypeId.equals("gene")){
			if((the_parentName!=null)
				&&(the_parentName.indexOf("-R")>0)){
				System.out.println("DOES THIS EVER OCCUR????");
			}else{
				uniquename = idTxt;
			}
		}else if(tmpTypeId.equals("pseudogene")){
			uniquename = idTxt;
		}else if(tmpTypeId.equals("transposable_element")){
			uniquename = idTxt;
		}else{
			uniquename = idTxt;
			System.out.println("\tUNK TYPE<"+tmpTypeId
					+"> FOR <"+uniquename+">");
		}
//NEARLY OUT OF OPTIONS
		//if((uniquename==null)||(uniquename.equals(""))){
		//	uniquename = the_gf.getName();
		//}

		//LAST RESORT - GIVE UP HOPE
		if((uniquename==null)||(uniquename.equals(""))){
			uniquename = "UNKNOWN_UNIQUENAME";
		}

		//WRITE HEADER ATTRIBUTES
		//ID
		if(idTxt!=null){
			the_FeatNode.setAttribute("id",idTxt);
		}

		//NAME
		/******/
		if((the_gf.getName()!=null)
				&&(!(the_gf.getName().equals("")))){
			String tmpName = the_gf.getName();
			if(!(the_gf instanceof Annot)){
				//TRUNCATE '.3' FOR ALL FEATURES BUT ANNOT
				if(tmpName.endsWith(".3")){
					tmpName = tmpName.substring(
							0,tmpName.length()-2);
				}
			}
			if(the_gf instanceof FeatureSpan){
				if(the_parentName!=null){
					//System.out.println("REPLACE ID<"+the_gf.getId()
					//		+"> WITH PARENTNAME<"+the_parentName+">");
					//tmpName = uniquename.replace(the_gf.getId(),the_parentName);
					int pbIndx = the_parentName.indexOf("-");
					String parentBase = "";
					if(pbIndx>0){
						parentBase = the_parentName.substring(0,pbIndx);
					}
					int idIndx = the_gf.getId().indexOf(":");
					String idSffx = "";
					if(idIndx>0){
						idSffx = the_gf.getId().substring(idIndx);
					}
					tmpName = parentBase+idSffx;
				}
				//tmpName = getBase(the_parentName)+":"+m_ExonCount;
				if(m_isHet){
					tmpName = uniquename;
				}
			}
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"name",
					tmpName));
		}
		/******/
//FSSCHANGE
		/******
		String tmpName = getBase(the_parentName)+":"+m_ExonCount;
		if(m_isHet){
			tmpName = uniquename;
		}
		System.out.println("FSS_NAME<"+tmpName+">");
		the_FeatNode.appendChild(makeGenericNode(
				the_DOC,"name",
				tmpName));
		******/

		//UNIQUENAME
		if(uniquename!=null){
			if(!(the_gf instanceof Annot)){
				//TRUNCATE '.3' FOR ALL FEATURES BUT ANNOT
				if(uniquename.endsWith(".3")){
					uniquename = uniquename.substring(
							0,uniquename.length()-2);
				}
			}
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"uniquename",uniquename));
			//System.out.println("RRRR<"+uniquename+">");
		}
		//if(uniquename==null){
		//	System.out.println("FSS_UNIQUENAME<"+uniquename
		//		+"> for TYPE<"+tmpTypeId+"> ID<"+idTxt+">");
		//}

		//CHECK FOR MULTIPLE TRANSCRIPTS WITH SAME UNIQUENAME
		if(isvalidTransTYPE(tmpTypeId)){
			for(int u=0;u<m_TranUNList.size();u++){
				String oldun = (String)m_TranUNList.get(u);
				if(oldun.equals(uniquename)){
					System.out.println("ERROR: TRAN UNIQUENAME<"
							+uniquename+"> IS REPEATED");
				}
			}
			m_TranUNList.add(uniquename);
		}

		//ORGANISM_ID
		the_FeatNode.appendChild(makeGenericNode(
				the_DOC,"organism_id","Dmel"));

		//MD5CHECKSUM
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

		//TYPE_ID
		if(specialTypeId!=null){
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id",specialTypeId));
		}else if(tmpTypeId!=null){
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id",tmpTypeId));
		}

		//DATE
		if(the_gf.getdate()!=null){
			the_FeatNode.appendChild(makeChadoDateNode(
					the_DOC,"timelastmodified",
					the_gf.getdate().toString()));
		}

		//RESIDUES
		if(the_gf instanceof Annot){
			//SEQLEN
			if(the_gf.getSpan()!=null){
				the_FeatNode.appendChild(makeGenericNode(
						the_DOC,"seqlen",
						(""+the_gf.getSpan().getLength())));
			}else{
				the_FeatNode.appendChild(makeGenericNode(
						the_DOC,"seqlen",
						"0"));
			}
		}else if(the_gf instanceof FeatureSet){
			for(int i=0;i<the_gf.getGenFeatCount();i++){
				GenFeat gf = the_gf.getGenFeat(i);
				if((gf.getType()!=null)
					&&(gf.getType().equals("cdna"))){
					//WRITE THE RESIDUE AS THIS FEAT'S
					String tmpRes = cleanString(
							gf.getResidues());
					//SEQLEN
					if(tmpRes!=null){
						the_FeatNode.appendChild(
							makeGenericNode(the_DOC,
								"seqlen",
								""+tmpRes.length()));
					}
					the_FeatNode.appendChild(
						makeGenericNode(the_DOC,
							"residues",
							tmpRes));
				}
			}
		}else if(the_gf instanceof FeatureSpan){
			//SEQLEN
			if(the_gf.getSpan()!=null){
				the_FeatNode.appendChild(makeGenericNode(
						the_DOC,"seqlen",
						(""+the_gf.getSpan().getLength())));
			}
		}

		//DBXREF_ID
		if((the_gf.getType()!=null)
				&&((the_gf.getType().equals("gene"))
				||(isvalidTransTYPE(the_gf.getType())))){
			if(isvalidIdTYPE(the_gf.getId())){
				the_FeatNode.appendChild(
						makeDbxrefIdAttrNode(the_DOC,
						"Gadfly",the_gf.getId()));
			}
		}

		//FEATURE_DBXREF
		//System.out.println("FEATURE_DBXREF");
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					the_FeatNode.appendChild(
						makeFeatureDbxrefAttrNode(
						the_DOC,attr));
				}
			}
		}

		//AUTHOR
		if(the_gf.getAuthor()!=null){
			the_FeatNode.appendChild(makeFeaturePropNode(
					the_DOC,"owner",the_gf.getAuthor()));
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
						//MAY NEED TO BE DEFERRED
						//UNTIL AFTER THE
						//FEATURE_RELATIONSHIP!
						the_FeatNode.appendChild(
							makeFeaturePropAttrNode(the_DOC,attr));
					}
				}
			}
		}

		//PROPERTY WHICH IS NOT A protein_id NOR internal_synonym
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

		//System.out.println("INTERNAL_SYNONYM");
		//INTERNAL SYNONYM FROM GAME internal_synonym PROPERTY
		boolean synAlreadyHere = false;
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("property")){
					//System.out.println("\tCOULDBE TYPE<"+attr.gettype()+"> VAL<"+attr.getvalue()+">");
					if(attr.gettype().equals("internal_synonym")){
						//System.out.println("\tMADE <"+attr.getisinternal()+">");
						String isCurr = "0";
						if((attr.getvalue()!=null)
								&&(uniquename!=null)
								&&(attr.getvalue().equals(uniquename))){
							isCurr = "1";
						}
						the_FeatNode.appendChild(makeFeatureSynonym(the_DOC,
								attr.getvalue(),
								attr.getisinternal(),
								the_gf.getAuthor(),isCurr));
						if((attr.getvalue()!=null)
							&&(uniquename!=null)
							&&(attr.getvalue().equals(uniquename))){
								synAlreadyHere = true;
						}
					}
				}
			}
		}

		//FEATLOC
		//SPAN
		//ONLY ADJUST A SPAN TO NEW COORDINATES IF IT IS WITH RESPECT
		//TO THE REF_SPAN, OTHER AltSpan()s FROM <result_span> SHOULD
		//NOT BE ADJUSTED
		if(the_gf.getSpan()!=null){
			/***********/
			Span sp = the_gf.getSpan();
			Span tmp_span = sp;
			//FRANK
			if((m_OldREFSTRING!=null)&&(sp.getSrc()!=null)
					&&((sp.getSrc().equals(m_OldREFSTRING)
					||(sp.getSrc().toLowerCase().equals(m_OldREFSTRING))))){
				tmp_span = sp.advance(m_REFSPAN.getStart()-1);
				if(m_isHet){
					if(tmp_span.getStart()<tmp_span.getEnd()){
						tmp_span = new Span(
								(tmp_span.getStart()+1),
								tmp_span.getEnd(),
								tmp_span.getSrc());
					}else{
						tmp_span = new Span(tmp_span.getStart(),
								(tmp_span.getEnd()+1),
								tmp_span.getSrc());
					}
				}
				//System.out.println("MFL ADVANCING ID<"
				//		+sp.getSrc()
				//		+">\tSP<"+sp.toString()
				//		+">\tTO<"+tmp_span.toString()+">");
			}
			/***********/
			the_FeatNode.appendChild(makeFeatureLoc(the_DOC,
					tmp_span,true));
		}
		if(the_gf.getAltSpan()!=null){
			/***********/
			Span sp2 = the_gf.getAltSpan();
			Span tmp_span2 = sp2;
			//FRANK
			if((m_OldREFSTRING!=null)&&(sp2.getSrc()!=null)
					&&((sp2.getSrc().equals(m_OldREFSTRING)
					||(sp2.getSrc().toLowerCase().equals(m_OldREFSTRING))))){
				tmp_span2 = sp2.advance(m_REFSPAN.getStart()-1);
				if(m_isHet){
					if(tmp_span2.getStart()<tmp_span2.getEnd()){
						tmp_span2 = new Span(
								(tmp_span2.getStart()+1),
								tmp_span2.getEnd(),
								tmp_span2.getSrc());
					}else{
						tmp_span2 = new Span(tmp_span2.getStart(),
								(tmp_span2.getEnd()+1),
								tmp_span2.getSrc());
					}
				}
				//System.out.println("MFL ADVANCING ID<"
				//		+sp2.getSrc()
				//		+">\tSP<"+sp2.toString()
				//		+">\tTO<"+tmp_span2.toString()+">");
			}
			/***********/
			the_FeatNode.appendChild(makeFeatureLoc(the_DOC,
					tmp_span2,true));
		}

		//System.out.println("DONE FEAT HEADER");
		return the_FeatNode;
	}

	public Element makeChadoDateNode(Document the_DOC,
			String the_timeelement,String the_timestring){
		Element time = (Element)the_DOC.createElement(the_timeelement);
		String chadoDate = DateConv.GameDateToChadoDate(the_timestring);
		time.appendChild(the_DOC.createTextNode(chadoDate));
		return time;
	}


	public String getTranSuffix(String the_name){
		String suffix = "";
		if(the_name==null){
			return null;
		}
		int indx = the_name.lastIndexOf("-R");
		if(indx>0){
			suffix = the_name.substring(indx);
		}
		return suffix;
	}

	public String getProtSuffix(String the_name){
		String suffix = "";
		if(the_name==null){
			return null;
		}
		int indx = the_name.lastIndexOf("-P");
		if(indx>0){
			suffix = the_name.substring(indx);
		}
		return suffix;
	}

	public String getBase(String the_str){
		if(the_str!=null){
			int indx = the_str.lastIndexOf("-");
			if(indx>0){
				the_str = the_str.substring(0,indx);
			}
		}
		return the_str;
	}

	public Element makeFeatureSynonym(Document the_DOC,String the_synonymTxt,String the_internalFlag,String the_Author,String the_isCurrent){
		Element fsNode = (Element)the_DOC.createElement("feature_synonym");
		fsNode.appendChild(makeGenericNode(the_DOC,"is_internal",the_internalFlag));
		//SYNONYM_ID
		Element synIdNode = (Element)the_DOC.createElement("synonym_id");
		Element synNode = (Element)the_DOC.createElement("synonym");
		synNode.appendChild(makeGenericNode(the_DOC,"name",
				the_synonymTxt));
		synNode.appendChild(makeGenericNode(the_DOC,"synonym_sgml",
				the_synonymTxt));
		synNode.appendChild(makeGenericNode(the_DOC,"type_id",
				"synonym"));
		synIdNode.appendChild(synNode);
		fsNode.appendChild(synIdNode);
		//PUB_ID
		String pubId = null;//"curator";
		if(the_Author!=null){
			pubId = the_Author;//+" "+pubId;
		}else{
			pubId = "gadfly3";//+" "+pubId;
		}
		fsNode.appendChild(makeGenericNode(the_DOC,"pub_id",pubId));
		fsNode.appendChild(makeGenericNode(the_DOC,"is_current",the_isCurrent));
		return fsNode;
	}

	public Element makeGenericNode(Document the_DOC,
			String the_type,String the_text){
		Element genNode = (Element)the_DOC.createElement(the_type);
		if(the_text!=null){
			genNode.appendChild(the_DOC.createTextNode(the_text));
		}
		return genNode;
	}

	public Element makeFeaturePropNode(Document the_DOC,
			String the_pkey_id,String the_pval){
		Element fpNode = (Element)the_DOC.createElement("featureprop");
		if(the_pkey_id!=null){
			fpNode.appendChild(makeGenericNode(
					the_DOC,"type_id",the_pkey_id));
		}
		if(the_pval!=null){
			fpNode.appendChild(makeGenericNode(
					the_DOC,"value",the_pval));
		}
		return fpNode;
	}

	public Element makeFeaturePropAttrNode(Document the_DOC,
			Attrib the_attr){
		String prefix = null;
		Element atNode = (Element)the_DOC.createElement("featureprop");
		if(the_attr.gettype()!=null){
			atNode.appendChild(makeGenericNode(
					the_DOC,"type_id",the_attr.gettype()));
		}
		if(the_attr.getvalue()!=null){
			//Element pval = (Element)the_DOC.createElement("pval");
			Element pval = (Element)the_DOC.createElement("value");
			String tmp = the_attr.getvalue();
			if(the_attr.gettimestamp()!=null){
				String chadoDate = DateConv.GameTimestampToChadoDate(
						the_attr.gettimestamp());
			//if(the_attr.getdate()!=null){
			//	String chadoDate = DateConv.GameDateToChadoDate(
			//			the_attr.getdate().toString());
				tmp += "::DATE:"+chadoDate;
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

	public Element makeDbxrefIdAttrNode(Document the_DOC,
			String the_xref_db,String the_xref_id){
		Element atNode = (Element)the_DOC.createElement("dbxref_id");
		Element dbxrefNode = (Element)the_DOC.createElement("dbxref");
		if(the_xref_id!=null){
			dbxrefNode.appendChild(makeGenericNode(
					the_DOC,"accession",the_xref_id));
		}
		if(the_xref_db!=null){
			String dbname = convertDB_NAME(the_xref_db);
			dbxrefNode.appendChild(makeGenericNode(
					the_DOC,"db_id",dbname));
		}
		atNode.appendChild(dbxrefNode);
		return atNode;
	}

	public Element makeFeatureDbxrefAttrNode(Document the_DOC,Attrib the_attr){
		Element attributeNode = (Element)the_DOC.createElement("feature_dbxref");
		attributeNode.appendChild(makeDbxrefIdAttrNode(the_DOC,
				the_attr.getxref_db(),the_attr.getdb_xref_id()));
		return attributeNode;
	}

	public Element makeCommentAttrNode(Document the_DOC,Attrib the_attr){
		Element attributeNode = (Element)the_DOC.createElement("featureprop");
		Element pkey_id = (Element)the_DOC.createElement("type_id");
		pkey_id.appendChild(the_DOC.createTextNode("comment"));
		attributeNode.appendChild(pkey_id);
		if(the_attr.gettext()!=null){
			Element pval = (Element)the_DOC.createElement("value");
			String tmp = the_attr.gettext();
			//if(the_attr.getdate()!=null){
			//	String chadoDate = DateConv.GameDateToChadoDate(
			//			the_attr.getdate().toString());
			if(the_attr.gettimestamp()!=null){
				String chadoDate = DateConv.GameTimestampToChadoDate(
						the_attr.gettimestamp());
				tmp += "::DATE:"+chadoDate;
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

	//public Element makeGameTempStorage(Document the_DOC,
	//		String the_pkey,String the_pval){
	//	Element atNode = (Element)the_DOC.createElement("featureprop");
	//	atNode.appendChild(makeGenericNode(the_DOC,"type_id",the_pkey));
	//	atNode.appendChild(makeGenericNode(the_DOC,"value",the_pval));
	//	return atNode;
	//}

	public Element makeFeatureLoc(Document the_DOC,Span the_span,
			boolean the_advance){
		Element featloc = (Element)the_DOC.createElement("featureloc");
		Element srcfeat = (Element)the_DOC.createElement("srcfeature_id");

		//System.out.println("MAKEFEATURELOC SPAN<"+the_span.getSrc()+">");
		String refStr = null;
		Span tmp_span = the_span;

		if(the_advance){
			if((m_OldREFSTRING!=null)&&(the_span.getSrc()!=null)
					&&(the_span.getSrc().equals(m_OldREFSTRING))){
				refStr = m_NewREFSTRING;
			}else{
				refStr = the_span.getSrc();
			}
		}

		if(refStr!=null){
			srcfeat.appendChild(the_DOC.createTextNode(refStr));
			featloc.appendChild(srcfeat);
		}

		int localMin = tmp_span.getStart();
		int localMax = tmp_span.getEnd();
		if(localMin>tmp_span.getEnd()){
			localMin = tmp_span.getEnd();
		}
		if(localMax<tmp_span.getStart()){
			localMax = tmp_span.getStart();
		}

		//NBEG
		Element nbeg = (Element)the_DOC.createElement("fmin");
		nbeg.appendChild(the_DOC.createTextNode((""+localMin)));
		featloc.appendChild(nbeg);

		//NEND
		Element nend = (Element)the_DOC.createElement("fmax");
		nend.appendChild(the_DOC.createTextNode((""+localMax)));
		featloc.appendChild(nend);

		//STRAND
		Element strand = (Element)the_DOC.createElement("strand");
		if(tmp_span.isForward()){
			strand.appendChild(the_DOC.createTextNode("1"));
		}else{
			strand.appendChild(the_DOC.createTextNode("-1"));
		}
		featloc.appendChild(strand);
		return featloc;
	}



	public void preprocessCVTerms(GenFeat the_TopNode){
	//EXCLUDE TEs FOR NOW
	if((the_TopNode.getId()!=null)&&(the_TopNode.getId().startsWith("TE"))){
		return;
	}

	if((the_TopNode instanceof ModFeat)
			||(the_TopNode instanceof NewModFeat)
			||(the_TopNode instanceof Seq)){
		//IGNORE
	}else if(the_TopNode instanceof Aspect){
		storePUB("Gadfly","curator");
		if(((Aspect)the_TopNode).getFunction()!=null){
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
	}else{
		if((m_modeflags==WRITEALL)||(the_TopNode.isChanged())){

		if((m_parseflags==GameSaxReader.PARSEALL)
				||(the_TopNode instanceof Annot)
				||(the_TopNode instanceof FeatureSet)
				||(the_TopNode instanceof FeatureSpan)){

			//SYNONYM
			if((the_TopNode.getId()!=null)
					&&(the_TopNode.getName()!=null)
					&&(!(the_TopNode.getId().equals(
					the_TopNode.getName())))){
				storeCV("synonym","synonym type");
			}

			//TYPES
			//FIX TO GET AROUND BUG WHERE GAME LISTS THE
			//EXON TYPE AS 'piecegenie' OR SOME SUCH TRIPE
			if(the_TopNode instanceof FeatureSpan){
					the_TopNode.setType(convertExonTYPE(
							the_TopNode.getType()));
			}

			if((the_TopNode.getType()!=null)
					&&(the_TopNode.getType().equals("gene"))
					&&(the_TopNode instanceof FeatureSet)){
				the_TopNode.setType("mRNA");
			}

			if(the_TopNode.getType()!=null){
				storeCV(convertTYPE(the_TopNode.getType()),"SO");
			}else{
				//NO TYPE - NEED TO GUESS
				if((the_TopNode.getId()!=null)
						&&(the_TopNode.getId().indexOf("-R")>0)){
					storeCV(convertTYPE("mRNA"),"SO");
				}else if((the_TopNode.getId()!=null)
						&&(the_TopNode.getId().indexOf("-P")>0)){
					storeCV("protein","SO");
				}
			}

			//AUTHOR
			if(the_TopNode.getAuthor()!=null){
				storeCV("owner","property type");
				storePUB(the_TopNode.getAuthor(),"curator");
			}

			//DBXREF_ID
			//System.out.println("\t\tTOPNODETYPE<"
			//	+the_TopNode.getType()
			//	+"> ID<"+the_TopNode.getId()+">");
			/********
			if((the_TopNode.getType()!=null)
					&&((the_TopNode.getType().equals("gene"))
					||(the_TopNode.getType().startsWith("transposable"))
					||(isvalidTransTYPE(the_TopNode.getType())))){

				System.out.println("DBXREF_ID<"
						+the_TopNode.getId()+">");
				if(isvalidIdTYPE(the_TopNode.getId())){
						storeDB("Gadfly");
						System.out.println("IS_VALID_ID_TYPE");
				}
			}
			********/
			storeDB("Gadfly");

			//FEATURE_DBXREF
			for(int i=0;i<the_TopNode.getAttribCount();i++){
				Attrib attr = the_TopNode.getAttrib(i);
				if(attr!=null){
				String atTp = attr.getAttribType();
				if(atTp!=null){
					if(atTp.equals("dbxref")){
						storeDB(convertDB_NAME(attr.getxref_db()));
					}else if(atTp.equals("comment")){
						storeCV(attr.getAttribType(),"property type");
					}else if(atTp.equals("internal_synonym")){
						storeCV("synonym","synonym type");
					}else{
						//System.out.println("ATTR<"+attr.getAttribType()+">");
					}
				}
				if(attr.gettype()!=null){
					if(attr.gettype().equals("internal_synonym")){					
						storeCV("synonym","synonym type");
					}else if(attr.gettype().equals("evidence")){					
						storeCV(attr.gettype(),"property type");
					}else if(attr.gettype().equals("evidenceGB")){					
						storeCV(attr.gettype(),"GenBank feature qualifier");
					}else{
						storeCV(attr.gettype(),"property type");
						//System.out.println("STORING CV<"+attr.gettype()+"> OF TYPE PROP_TYPE");
						//attr.Display(1);
					}
				}
				if(attr.getperson()!=null){
					storePUB(attr.getperson(),"curator");
				}
				}
			}
		}

		//RECURSE
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			preprocessCVTerms(gf);
		}
		}
	}//END EXCLUDE MODFEAT
	}

	public Element makePreamble(Document the_DOC,Element the_Elem){
		if(m_CVList!=null){
			Iterator it = m_CVList.iterator();
			while(it.hasNext()){
				String txt = (String)it.next();
				the_Elem.appendChild(createCV(the_DOC,txt));
			}
		}
		if(m_DBList!=null){
			Iterator it = m_DBList.iterator();
			while(it.hasNext()){
				String txt = (String)it.next();
				the_Elem.appendChild(createDB(the_DOC,txt));
			}
		}
		if(m_CVTERMList!=null){
			Iterator it1 = m_CVTERMList.iterator();
			while(it1.hasNext()){
				String txt = (String)it1.next();
				int indx = 0;
				if((indx = txt.indexOf("|"))>0){
					String txt1 = txt.substring(0,indx);
					if(isvalidCVTERM(txt1)){
						String txt2 = txt.substring(indx+1);
						the_Elem.appendChild(createCVTERM(the_DOC,txt1,txt2));
					}
				}
			}
		}
		//PUBLICATIONS
		if(m_PUBList!=null){
			Iterator it2 = m_PUBList.iterator();
			while(it2.hasNext()){
				String txt = (String)it2.next();
				txt = convertPUB_NAME(txt);
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
		the_cvTxt = convertTYPE(the_cvTxt);
		m_CVList.add(the_cvTxt);
	}

	public void storeCV(String the_cvTxt,String the_cvtermTxt){
		if(m_CVList==null){
			m_CVList = new HashSet();
		}
		if(m_CVTERMList==null){
			m_CVTERMList = new HashSet();
		}
		the_cvTxt = convertTYPE(the_cvTxt);
		m_CVList.add(the_cvtermTxt);
		m_CVTERMList.add(the_cvTxt+"|"+the_cvtermTxt);
	}

	public Element createCV(Document the_DOC,String txt){
		Element cv = (Element)the_DOC.createElement("cv");
		//cv.setAttribute("op","lookup");
		cv.setAttribute("id",txt);
		Element cvname = (Element)the_DOC.createElement("name");
		cvname.appendChild(the_DOC.createTextNode(txt));
		cv.appendChild(cvname);
		return cv;
	}

	public Element createDB(Document the_DOC,String txt){
		Element db = (Element)the_DOC.createElement("db");
		db.setAttribute("op","lookup");
		db.setAttribute("id",txt);
		Element dbname = (Element)the_DOC.createElement("name");
		dbname.appendChild(the_DOC.createTextNode(txt));
		db.appendChild(dbname);
		return db;
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

	public void storeDB(String the_dbTxt){
		if(m_DBList==null){
			m_DBList = new HashSet();
		}
		m_DBList.add(the_dbTxt);
	}

	public Element createPUB(Document the_DOC,String the_txt){
		Element pub = (Element)the_DOC.createElement("pub");
		if(the_txt.startsWith("Gad")){
			pub.setAttribute("op","force");
		}else{
			pub.setAttribute("op","lookup");
		}
		pub.setAttribute("id",the_txt);
		/**************
		//OLD STYLE PUB_ID
		Element miniref = (Element)the_DOC.createElement("miniref");
		miniref.appendChild(the_DOC.createTextNode(the_txt));
		pub.appendChild(miniref);
		Element type_id = (Element)the_DOC.createElement("type_id");
		type_id.appendChild(the_DOC.createTextNode("curator"));
		pub.appendChild(type_id);
		**************/
		/**************/
		//NEW STYLE PUB_ID
		Element uniquename = (Element)the_DOC.createElement("uniquename");
		uniquename.appendChild(the_DOC.createTextNode(the_txt));
		pub.appendChild(uniquename);
		Element type_id = (Element)the_DOC.createElement("type_id");
		type_id.appendChild(the_DOC.createTextNode("computer file"));
		pub.appendChild(type_id);
		/**************/
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

	public String convertDB_NAME(String the_dbname){
		if(the_dbname==null){
			return null;
		}else if(the_dbname.equalsIgnoreCase("gadfly")){
			return "Gadfly";
		}else if((the_dbname.equalsIgnoreCase("flybase"))
				||(the_dbname.equalsIgnoreCase("FB"))){
			return "FlyBase";
		}else if(the_dbname.equalsIgnoreCase("genbank")){
			return "genbank";
		}else if(the_dbname.equalsIgnoreCase("gb")){
			return "genbank";
		}else{
			return the_dbname;
		}
	}

	public String convertPUB_NAME(String the_pubname){
		if(the_pubname==null){
			return null;
		}else if(the_pubname.equalsIgnoreCase("gadfly")){
			return "gadfly3";
		}else{
			return the_pubname;
		}
	}

	public String convertTYPE(String the_term){
		//System.out.println("CONVERTING<"+the_term+">");
		if(the_term==null){
			return "NNNN";
		}else if(the_term.equals("cdna")){
			return "cDNA";
		}else if(the_term.equals("transcript")){
			return "mRNA";
		}else if(the_term.equals("transposable_element")){
			return "transposable_element";
		}else if(the_term.equals("transposon")){
			return "transposable_element";
		}else if(the_term.equals("aa")){
			return "protein";
		}else if(the_term.equals("pseudogene")){
			return "pseudogene";
		}else if(the_term.equals("pseudotranscript")){
			return "mRNA";
		}else if(the_term.startsWith("misc. non-coding RNA")){
			return "ncRNA";
		}else if(the_term.startsWith("microRNA")){
			return "nuclear_micro_RNA_coding_gene";
		}else if(the_term.startsWith("miscellaneous curator's observation")){
			return "remark";
		}else{
			return the_term;
		}
	}

	public String convertExonTYPE(String the_term){
		if(the_term==null){
			return null;
		}
		if((the_term.equals("start_codon"))
				||(the_term.equals("protein"))
				||(the_term.equals("exon"))){
			return the_term;
		}else if(the_term.startsWith("translate")){
			return "start_codon";
		}else{
			//System.out.println("PREPROCESS CONVERT EXON TYPE<"
			//		+the_term+"> TO <exon>");
			return "exon";
		}
	}

	public boolean isvalidTransTYPE(String the_type){
		if(the_type==null){
			return false;
		}
		if((the_type.equals("mRNA"))
				||(the_type.equals("tRNA"))
				||(the_type.equals("rRNA"))
				||(the_type.equals("snRNA"))
				||(the_type.equals("snoRNA"))
				||(the_type.equals("nuclear_micro_RNA_coding_gene"))
				||(the_type.equals("pseudogene"))
				||(the_type.equals("remark"))
				||(the_type.equals("ncRNA"))){
			return true;
		}else{
			return false;
		}
	}

	public boolean isvalidCVTERM(String the_term){
		if(the_term==null){
			return false;
		}else if(the_term.equals("start_codon")){
			return false;
		}
		return true;
	}

	public boolean isvalidIdTYPE(String the_term){
		if(the_term==null){
			return false;
		}
		if((the_term.startsWith("CG"))
				||(the_term.startsWith("CR"))){
			return true;
		}
		return false;
	}

/******************************/
	public Vector makeAnalysisNode(Document the_DOC,GenFeat the_gf){
		//System.out.println("START COMPUTATIONAL_ANALYSIS NODE TYPE<"
		//		+the_gf.getProgram()+">");

		Vector list = new Vector();

		String idStr = null;
		String nameStr = null;
		String uniquenameStr = null;
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			Element featNode = (Element)the_DOC.createElement("feature");
			idStr = gf.getId();
			nameStr = gf.getName();
			uniquenameStr = gf.getId();

			//ID
			if(gf.getId()!=null){
				featNode.setAttribute("id",gf.getId());
			}

			//DATE
			//if(gf.getdate()!=null){
			//	featNode.appendChild(makeChadoDateNode(
			//			the_DOC,"timeaccessioned",
			//			gf.getdate().toString()));
			//}

			//NAME
			if(nameStr==null){
				nameStr = "PROBLEM"+gf.getName();
			}
			if(nameStr!=null){
				featNode.appendChild(makeGenericNode(
						the_DOC,"name",nameStr));
			}

			//DATE
			if(gf.getdate()!=null){
				featNode.appendChild(makeChadoDateNode(
						the_DOC,"timelastmodified",
						gf.getdate().toString()));
			}

			//SEQLEN
			if(gf.getResidueLength()!=null){
				featNode.appendChild(makeGenericNode(
						the_DOC,"seqlen",gf.getResidueLength()));
			}else{
				featNode.appendChild(makeGenericNode(
						the_DOC,"seqlen","0"));
			}

			//UNIQUENAME
			if(uniquenameStr==null){
				uniquenameStr = "PROBLEM"+gf.getId();
			}

			uniquenameStr = uniquenameStr+"_"+the_gf.getProgram();
			System.out.println("CCCCCC<"+uniquenameStr+">");
			featNode.appendChild(makeGenericNode(
					the_DOC,"uniquename",uniquenameStr));

			//MD5CHECKSUM
			if(gf.getMd5()!=null){
				featNode.appendChild(makeGenericNode(
						the_DOC,"md5checksum",gf.getMd5()));
			}

			//ORGANISM_ID
			featNode.appendChild(makeCAOrganismId(the_DOC,
					"Computational","Result"));

			//TYPE_ID
			featNode.appendChild(makeGenericNode(
					the_DOC,"type_id","match"));

			//ANALYSIS
			featNode.appendChild(makeGenericNode(
					the_DOC,"is_analysis","1"));

			featNode.appendChild(makeAnalysisfeatureNode(the_DOC,the_gf));

			for(int j=0;j<gf.getGenFeatCount();j++){
				GenFeat gff = gf.getGenFeat(j);
				//System.out.println("TRYING TO SET DB<"+the_gf.getDatabase()+"> PROG<"+the_gf.getProgram()+"> FOR UN<"+gff.getId()+">");
				gff.setDatabase(the_gf.getDatabase());
				gff.setProgram(the_gf.getProgram());
				featNode.appendChild(makeCAFeatRel(the_DOC,"partof",
						makeRSFeature(the_DOC,gff)));
			}
			list.add(featNode);
		}

		//System.out.println("END COMPUTATIONAL_ANALYSIS NODE");
		//return featNode;
		return list;
	}
/******************************/

	public Element makeAnalysisfeatureNode(Document the_DOC,GenFeat the_gf){
		//System.out.println("\tSTART ANALYSIS_FEATURE NODE");
		Element afNode = (Element)the_DOC.createElement("analysisfeature");
		Element aidNode = (Element)the_DOC.createElement("analysis_id");
		Element aNode = (Element)the_DOC.createElement("analysis");
		if(the_gf.getDatabase()!=null){
			aNode.appendChild(makeGenericNode(
					the_DOC,"sourcename",the_gf.getDatabase()));
		}
//RRR WRONG DATE
		//DATE
		if(the_gf.getdate()!=null){
			aNode.appendChild(makeChadoDateNode(
					the_DOC,"timeexecuted",
					the_gf.getdate().toString()));
		}
		//1.0
		aNode.appendChild(makeGenericNode(
				the_DOC,"sourceversion","1.0"));
		//sim4
		if(the_gf.getProgram()!=null){
			aNode.appendChild(makeGenericNode(
					the_DOC,"program",the_gf.getProgram()));
		}
		//1.0
		aNode.appendChild(makeGenericNode(
				the_DOC,"programversion","1.0"));
		aidNode.appendChild(aNode);
		afNode.appendChild(aidNode);
		if(the_gf.getScore()!=null){
			afNode.appendChild(makeGenericNode(
					the_DOC,"rawscore",the_gf.getScore()));
		}
		//System.out.println("\tEND ANALYSIS_FEATURE NODE");
		return afNode;
	}

	public Element makeCAFeatRel(Document the_DOC,String the_relType,
			Element the_subjFeat){
			//subject_id,type_id
		//System.out.println("\tSTART FEAT_REL NODE");
		Element featrel = (Element)the_DOC.createElement(
				"feature_relationship");
		Element subjfeat = (Element)the_DOC.createElement("subject_id");
		subjfeat.appendChild(the_subjFeat);
		featrel.appendChild(subjfeat);
		featrel.appendChild(makeGenericNode(
				the_DOC,"type_id",the_relType));
		//System.out.println("\tEND FEAT_REL NODE");
		return featrel;
	}

	public Element makeRSFeature(Document the_DOC,GenFeat the_gf){
		System.out.println("\tSTART RESULT_SET FEATURE ID<"+the_gf.getId()
				+"> NAME<"+the_gf.getName()+">");
		Element RSfeat = (Element)the_DOC.createElement("feature");

		//String idStr = null;
		//for(int j=0;j<the_gf.getGenFeatCount();j++){
		//	GenFeat gff = the_gf.getGenFeat(j);
		//	idStr = gff.getId();
		//}
		if(the_gf.getId()!=null){
			RSfeat.appendChild(makeGenericNode(
					//the_DOC,"uniquename",idStr));
					the_DOC,"uniquename",the_gf.getId()));
		}

		RSfeat.appendChild(makeCAOrganismId(the_DOC,
				"Computational","Result"));

		//TYPE_ID
		RSfeat.appendChild(makeGenericNode(
				the_DOC,"type_id","match"));
		RSfeat.appendChild(makeGenericNode(
				the_DOC,"is_analysis","1"));

		RSfeat.appendChild(makeAnalysisfeatureNode(the_DOC,the_gf));

		String residues = the_gf.getResidues();
		String auxresidues = the_gf.getAuxResidues();
		//System.out.println("\t\t\tSHOULD WRITE SPANS FOR<"+the_gf.getId()+">");

		if(the_gf.getAltSpan()!=null){
			System.out.println("\t\t\t\tALT SPAN<"+the_gf.getAltSpan()
					+"> SRC<"+the_gf.getAltSpan().getSrc()+">");
			String srcStr = the_gf.getAltSpan().getSrc();
			String resFromChadoLevel = (String)m_SeqMap.get(srcStr);
			String descFromChadoLevel = (String)m_SeqDescMap.get(srcStr);
			//System.out.println("DESCFROMCHADO<"+descFromChadoLevel+">");
			Element srcf2 = makeCASrcFeatResult(the_DOC,
					the_gf,the_gf.getAltSpan().getSrc(),
//RESIDUECHANGE
					//auxresidues);
					//LOOK UP BASED ON SRC
					resFromChadoLevel,descFromChadoLevel);
			//System.out.println("SRC<"+the_gf.getAltSpan().getSrc()
			//		+">RFCL<"+resFromChadoLevel
			//		+">DFCL<"+descFromChadoLevel+">");
			Span altsp = the_gf.getAltSpan();
			altsp = altsp.advance(m_REFSPAN.getStart()-1);
			RSfeat.appendChild(makeCAFeatureLoc(
					the_DOC,altsp,
					true,srcf2,1,the_gf.getAltSpan().getAlignment()));
		}

		if(the_gf.getSpan()!=null){
			System.out.println("\t\t\t\tREG SPAN<"+the_gf.getSpan()
					+"> SRC<"+the_gf.getSpan().getSrc()+">");
			Element srcf1 = makeCASrcFeatRefr(the_DOC,the_gf,
					residues);
			//ADVANCE
			Span sp = the_gf.getSpan();
			sp = sp.advance(m_REFSPAN.getStart()-1);
			RSfeat.appendChild(makeCAFeatureLoc(
					the_DOC,sp,false,srcf1,0,
					the_gf.getSpan().getAlignment()));
		}
		//System.out.println("\t\tEND RESULT_SET");
		return RSfeat;
	}

	public Element makeCASrcFeatRefr(Document the_DOC,GenFeat the_gf,
			String the_auxresidues){
		System.out.println("\t\tRESULT_SPAN REFR ID<"+the_gf.getId()
				+"> NAME<"+the_gf.getName()+">");
		Element srcFeat = (Element)the_DOC.createElement("feature");
		//NAME
		if((m_ulflags==0)||(m_ulflags==HET)){
			if((the_gf.getSpan()!=null)
					&&(the_gf.getSpan().getSrc()!=null)){
				String spanSrc = the_gf.getSpan().getSrc();
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"name",spanSrc));
			}
		}else if(m_ulflags==REL4){
			if(m_NewREFSTRING!=null){
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"name",m_NewREFSTRING));
			}
		}
		//RESIDUES
		if(the_auxresidues!=null){
			String tmpRes = cleanString(the_auxresidues);
			srcFeat.appendChild(makeGenericNode(the_DOC,
					"residues",tmpRes));
		}
		//UNIQUENAME
		if(m_ulflags==0){
			if((the_gf.getSpan()!=null)
					&&(the_gf.getSpan().getSrc()!=null)){
				String spanSrc = the_gf.getSpan().getSrc();
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"uniquename",spanSrc));
				System.out.println("FFFFF<"+spanSrc+">");
			}
		}else if(m_ulflags==REL4){
			if(m_NewREFSTRING!=null){
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"uniquename",m_NewREFSTRING));
			}
		}

		//ORGANISM_ID
		srcFeat.appendChild(makeCAOrganismId(the_DOC,
				"Drosophila","melanogaster"));
		//TYPE_ID
		srcFeat.appendChild(makeGenericNode(
				the_DOC,"type_id","chromosome_arm"));
		//DBXREF_ID
		srcFeat.appendChild(makeDbxrefIdAttrNode(the_DOC,
				"Gadfly",m_NewREFSTRING));
		//System.out.println("\t\t\tEND RESULT_SPAN");
		return srcFeat;
	}

	public Element makeCASrcFeatResult(Document the_DOC,
			GenFeat the_gf,String the_src,
			String the_residues,String the_description){
		System.out.println("\t\tRESULT_SPAN RSLT ID<"+the_gf.getId()
				+"> NAME<"+the_gf.getName()+">");
		Element srcFeat = (Element)the_DOC.createElement("feature");

		//DATE
		//if(the_gf.getdate()!=null){
		//	srcFeat.appendChild(makeChadoDateNode(
		//			the_DOC,"timeaccessioned",
		//			the_gf.getdate().toString()));
		//}

		//NAME
		if(the_src!=null){
			srcFeat.appendChild(makeGenericNode(
					the_DOC,"name",the_src));
		}

		//RESIDUES
		if(the_residues!=null){
			String tmpRes = cleanString(the_residues);
			srcFeat.appendChild(makeGenericNode(the_DOC,
					"residues",tmpRes));
		}

		//DATE
		if(the_gf.getdate()!=null){
			srcFeat.appendChild(makeChadoDateNode(
					the_DOC,"timelastmodified",
					the_gf.getdate().toString()));
		}

		//UNIQUENAME
		if(the_src!=null){
			srcFeat.appendChild(makeGenericNode(
					the_DOC,"uniquename",the_src));
		}

		//ORGANISM_ID
		srcFeat.appendChild(makeCAOrganismId(the_DOC,
				"Computational","Result"));

		//TYPE_ID
		if(the_gf.getType()!=null){
			srcFeat.appendChild(makeGenericNode(
					the_DOC,"type_id",the_gf.getType()));
			srcFeat.appendChild(makeGenericNode(
					the_DOC,"is_analysis","1"));
		}else{
			if(the_gf instanceof FeatureSet){
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"type_id","mRNA"));
			}else if(the_gf instanceof FeatureSpan){
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"type_id","exon"));
			}else if(the_gf instanceof ResultSet){
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"type_id","match"));
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"is_analysis","1"));
			}else if(the_gf instanceof ResultSpan){
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"type_id","match"));
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"is_analysis","1"));
			}else{ //GIVE UP
				srcFeat.appendChild(makeGenericNode(
						the_DOC,"type_id","STUFF"));
			}
		}
		if(the_description!=null){
			srcFeat.appendChild(makeFeaturePropNode(
					the_DOC,"description",the_description));
		}
		//System.out.println("\t\t\tEND RESULT_SPAN");
		return srcFeat;
	}

	public Element makeCAOrganismId(Document the_DOC,
			String the_genus,String the_species){
		Element oiFeat = (Element)the_DOC.createElement("organism_id");
		Element oioFeat = (Element)the_DOC.createElement("organism");
		Element genusFeat = (Element)the_DOC.createElement("genus");
		genusFeat.appendChild(the_DOC.createTextNode(the_genus));
		oioFeat.appendChild(genusFeat);
		Element speciesFeat = (Element)the_DOC.createElement("species");
		speciesFeat.appendChild(the_DOC.createTextNode(the_species));
		oioFeat.appendChild(speciesFeat);
		oiFeat.appendChild(oioFeat);
		return oiFeat;
	}

	public Element makeCAFeatureLoc(Document the_DOC,Span the_span,
			boolean the_advance,Element the_srcFeat,int the_rank,String the_res_info){
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
		if(the_advance){
			if((m_OldREFSTRING!=null)&&(the_span.getSrc()!=null)
					&&(the_span.getSrc().equals(m_OldREFSTRING))){
				tmp_span = the_span.advance(m_REFSPAN.getStart()-1);
				refStr = m_NewREFSTRING;
			}else{
				refStr = the_span.getSrc();
			}
		}
		if(the_srcFeat!=null){
			srcfeat.appendChild(the_srcFeat);
			featloc.appendChild(srcfeat);
		}

		int localMin = tmp_span.getStart();
		int localMax = tmp_span.getEnd();
		if(localMin>tmp_span.getEnd()){
			localMin = tmp_span.getEnd();
		}
		if(localMax<tmp_span.getStart()){
			localMax = tmp_span.getStart();
		}

		//IS_FMIN_PARTIAL
		Element fmin_part = (Element)the_DOC.createElement(
				"is_fmin_partial");
		fmin_part.appendChild(the_DOC.createTextNode((""+0)));
		featloc.appendChild(fmin_part);

		//IS_FMAX_PARTIAL
		Element fmax_part = (Element)the_DOC.createElement(
				"is_fmax_partial");
		fmax_part.appendChild(the_DOC.createTextNode((""+0)));
		featloc.appendChild(fmax_part);

		//FMIN
		Element fmin = (Element)the_DOC.createElement("fmin");
		fmin.appendChild(the_DOC.createTextNode((""+localMin)));
		featloc.appendChild(fmin);

		//LOCGROUP
		Element locgroup = (Element)the_DOC.createElement("locgroup");
		locgroup.appendChild(the_DOC.createTextNode((""+0)));
		featloc.appendChild(locgroup);

		//RANK
		Element rank = (Element)the_DOC.createElement("rank");
		rank.appendChild(the_DOC.createTextNode((""+the_rank)));
		featloc.appendChild(rank);

		//RESIDUE_INFO
		if(the_res_info!=null){
			String tmp = the_res_info;
			if(tmp.length()>10){
				tmp = tmp.substring(0,9);
			}
			//System.out.println("CREATE RES_INFO["+m_resinf+"] <"+tmp+">");
			Element residueElem = (Element)the_DOC.createElement("residue_info");
			residueElem.appendChild(the_DOC.createTextNode((""+the_res_info)));
			featloc.appendChild(residueElem);
			m_resinf++;
		}

		//STRAND
		Element strand = (Element)the_DOC.createElement("strand");
		if(tmp_span.isForward()){
			strand.appendChild(the_DOC.createTextNode("1"));
		}else{
			strand.appendChild(the_DOC.createTextNode("-1"));
		}
		featloc.appendChild(strand);

		//FMAX
		Element fmax = (Element)the_DOC.createElement("fmax");
		fmax.appendChild(the_DOC.createTextNode((""+localMax)));
		featloc.appendChild(fmax);
		return featloc;
	}

	public void fillInBlankNames(String the_accName){
		//GIVE NAMES TO BLANK EXONS

		//CHECK FOR UNNAMED EXONS WHICH HAVE NAMED COPIES ELSEWHERE
		for(int i=0;i<m_RenExonList.size();i++){
			RenEx rei = (RenEx)m_RenExonList.get(i);
			if(rei.getName()==null){
				//CHECK BEFORE
				for(int j=0;j<m_RenExonList.size();j++){
					RenEx rej = (RenEx)m_RenExonList.get(j);
					if(i==j){
						//SKIP
					}else if(rei.getSpan().toString().equals(rej.getSpan().toString())){
						//HAVE SAME SPAN
						if(rej.getName()!=null){
							rei.setName(rej.getName());
						}
					}
				}
			}
		}

		//CALCULATE NEW ORDINAL NAMES FOR STILL UNNAMED EXONS
		int blankCnt = 0;
		int maxExonOrd = 0;
		int llfo = 0;
		for(int i=0;i<m_RenExonList.size();i++){
			RenEx re = (RenEx)m_RenExonList.get(i);
			if(re.getName()==null){
				blankCnt++;
			}else{
				int exonOrd = 0;
				int indx = re.getName().indexOf(":");
				if(indx>0){
					String exOrdStr = re.getName().substring(indx+1).trim();
					if(exOrdStr.startsWith("temp")){
						exonOrd = -1;
					}else{
						try{
							exonOrd = Integer.decode(exOrdStr).intValue();
						}catch(Exception ex){
						}
					}
				}
				re.setOrdinal(exonOrd);
			}
		}
		if(blankCnt>0){
			//System.out.println("\tHAS <"+blankCnt+"> BLANKS");
			for(int i=1;i<=blankCnt;i++){
				//System.out.println("START LFO");
				int lfo = getLowestFreeOrdinal(llfo);
				//System.out.println("LFO<"+lfo+">");
				for(int j=0;j<m_RenExonList.size();j++){
					RenEx re = (RenEx)m_RenExonList.get(j);
					if(re.getOrdinal()==0){
						re.setOrdinal(lfo);
						llfo = lfo;
						re.setName(the_accName+":"+lfo);
						j = m_RenExonList.size();
					}
				}
			}
		}
		//SORT
	}

	public int getLowestFreeOrdinal(int the_lastlowestfreeordinal){
		//int ord = 1;
		int ord = the_lastlowestfreeordinal+1;
		boolean found = true;
		while(found){
			found = false;
			for(int j=0;j<m_RenExonList.size();j++){
				RenEx re = (RenEx)m_RenExonList.get(j);
				//System.out.println("\tORDLOOKINGFOR<"+ord
				//		+"> CURORD<"
				//		+re.getOrdinal()+">");
				if(ord==re.getOrdinal()){
					found = true;
					ord++;
					j=m_RenExonList.size();
				}
			}
			if(found==false){
				return ord;
			}
		}
		return ord;
	}

	private void DisplayRenExon(){
		for(int i=0;i<m_RenExonList.size();i++){
			RenEx re = (RenEx)m_RenExonList.get(i);
			//System.out.println("\tEXON<"+re.getName()
			//		+"> SPAN<"+re.getSpan()+">");
		}
	}

	private String getRenExonName(Span exonSpan){
		if(m_RenExonList==null){
			return null;
		}
		for(int i=0;i<m_RenExonList.size();i++){
			RenEx re = (RenEx)m_RenExonList.get(i);
			Span sp = re.getSpan();
			if(sp.toString().equals(exonSpan.toString())){
				if(re.getName()!=null){
					return re.getName();
				}else{
					//return "MANUFACTURED_NAME";
				}
			}
		}
		return null;
	}

	public class RenEx{
		private String m_name = null;
		private Span m_span = null;
		private int m_ordinal = 0;

		public RenEx(String the_name,Span the_span){
			m_name = the_name;
			m_span = the_span;
		}

		public void setName(String the_name){
			m_name = the_name;
		}

		public String getName(){
			return m_name;
		}

		public Span getSpan(){
			return m_span;
		}

		public void setOrdinal(int the_ordinal){
			m_ordinal = the_ordinal;
		}

		public int getOrdinal(){
			return m_ordinal;
		}

		public String toString(){
			return ("NM<"+m_name+"> SP<"+m_span+">");
		}
	}
}



//ChadoSaxReader.java

import org.gmod.chado.chadxtogame.ChadoSaxReader;
import org.gmod.chado.chadxtogame.GenFeat;

//import org.xml.sax.helpers.DefaultHandler;
//import org.xml.sax.*;
//import org.xml.sax.Attributes;
//import org.xml.sax.SAXException;

//import com.sun.xml.tree.*;
//import com.sun.xml.parser.Parser.*;

//import javax.xml.parsers.*;
//import java.util.*;
//import java.io.*;

public class CSR {
	public static void main(String args[]){
		ChadoSaxReader pd = new ChadoSaxReader();
		String fn = "/users/smutniak/pinglei/dump_scaffold_local_id.xml";
		pd.parse(fn);
		GenFeat topnode = pd.getTopNode();
		topnode.Display(0);
	}
}



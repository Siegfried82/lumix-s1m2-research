import com.android.tools.smali.dexlib2.*;
import com.android.tools.smali.dexlib2.dexbacked.*;
import java.util.zip.*;
class ListNativeDex {
 public static void main(String[] a)throws Exception{try(var z=new ZipFile(a[0])){var es=z.entries();while(es.hasMoreElements()){var e=es.nextElement();if(!e.getName().matches("classes[0-9]*\\.dex"))continue;var d=new DexBackedDexFile(Opcodes.getDefault(),z.getInputStream(e).readAllBytes());for(var c:d.getClasses())for(var m:c.getMethods())if((m.getAccessFlags()&0x100)!=0)System.out.printf("{\"class\":\"%s\",\"method\":\"%s\",\"return\":\"%s\"}%n",c.getType(),m.getName(),m.getReturnType());}}}
}

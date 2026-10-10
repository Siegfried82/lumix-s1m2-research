import com.android.tools.smali.dexlib2.*;
import com.android.tools.smali.dexlib2.dexbacked.*;
import com.android.tools.smali.dexlib2.iface.instruction.*;
import java.util.zip.*;
class DumpDownloadDex {
 public static void main(String[] a)throws Exception{
 try(var z=new ZipFile(a[0])){var es=z.entries();while(es.hasMoreElements()){var e=es.nextElement();if(!e.getName().matches("classes[0-9]*\\.dex"))continue;
 var d=new DexBackedDexFile(Opcodes.getDefault(),z.getInputStream(e).readAllBytes());
 for(var c:d.getClasses())if(c.getType().equals("LH5/c;"))for(var m:c.getMethods())if(m.getImplementation()!=null){System.out.println("METHOD "+m.getName());int p=0;for(var i:m.getImplementation().getInstructions()){
 String s=String.format("%04x %s",p,i.getOpcode().name);
 if(i instanceof OneRegisterInstruction r)s+=" A=v"+r.getRegisterA();
 if(i instanceof TwoRegisterInstruction r)s+=" B=v"+r.getRegisterB();
 if(i instanceof OffsetInstruction o)s+=String.format(" target=%04x",p+o.getCodeOffset());
 if(i instanceof NarrowLiteralInstruction l)s+=" literal="+l.getNarrowLiteral();
 if(i instanceof ReferenceInstruction r)s+=" ref="+r.getReference();
 if(i instanceof FiveRegisterInstruction r)s+=" regs="+r.getRegisterC()+","+r.getRegisterD()+","+r.getRegisterE()+","+r.getRegisterF()+","+r.getRegisterG()+" count="+r.getRegisterCount();
 System.out.println(s);p+=i.getCodeUnits();}}}}}
}

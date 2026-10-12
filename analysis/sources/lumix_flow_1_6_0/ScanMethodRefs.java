import com.android.tools.smali.dexlib2.Opcodes;
import com.android.tools.smali.dexlib2.dexbacked.DexBackedDexFile;
import com.android.tools.smali.dexlib2.iface.ClassDef;
import com.android.tools.smali.dexlib2.iface.Method;
import com.android.tools.smali.dexlib2.iface.instruction.Instruction;
import com.android.tools.smali.dexlib2.iface.instruction.ReferenceInstruction;
import com.android.tools.smali.dexlib2.iface.reference.FieldReference;
import com.android.tools.smali.dexlib2.iface.reference.MethodReference;
import java.util.zip.ZipFile;
import java.util.zip.ZipEntry;

class ScanMethodRefs {
    public static void main(String[] args) throws Exception {
        int dexCount=0, classCount=0, methodCount=0, instructionCount=0, referenceCount=0;
        try (ZipFile zip = new ZipFile(args[0])) {
            var entries = zip.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                if (!entry.getName().matches("classes[0-9]*\\.dex")) continue;
                dexCount++;
                byte[] bytes = zip.getInputStream(entry).readAllBytes();
                DexBackedDexFile dex = new DexBackedDexFile(Opcodes.getDefault(), bytes);
                for (ClassDef cls : dex.getClasses()) {
                    classCount++;
                    for (Method method : cls.getMethods()) {
                        if (method.getImplementation() == null) continue;
                        methodCount++;
                        int offset=0;
                        for (Instruction insn : method.getImplementation().getInstructions()) {
                            instructionCount++;
                            if (insn instanceof ReferenceInstruction ri && ri.getReference() instanceof MethodReference f
                                && f.getDefiningClass().equals(args[1]) && !cls.getType().equals(args[1])) {
                                referenceCount++;
                                System.out.printf("{\"dex\":\"%s\",\"class\":\"%s\",\"method\":\"%s\",\"code_unit_offset\":%d,\"opcode\":\"%s\",\"target_method\":\"%s\"}%n",
                                    entry.getName(), cls.getType(), method.getName(), offset, insn.getOpcode().name, f.getName());
                            }
                            offset += insn.getCodeUnits();
                        }
                    }
                }
            }
        }
        System.out.printf("{\"summary\":true,\"dex_count\":%d,\"class_count\":%d,\"implemented_method_count\":%d,\"instruction_count\":%d,\"references\":%d}%n",
            dexCount,classCount,methodCount,instructionCount,referenceCount);
    }
}

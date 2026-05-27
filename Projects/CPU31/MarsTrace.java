import mars.*;
import mars.assembler.*;
import mars.simulator.*;
import mars.mips.hardware.*;
import mars.util.*;
import java.io.*;
import java.util.*;

/**
 * MarsTrace — step through a MIPS assembly program and dump per-instruction
 * register state in testbench-compatible format.
 *
 * Usage: java -cp Mars4_5.jar:. MarsTrace <asm_file>
 */
public class MarsTrace {

    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Usage: java -cp Mars4_5.jar:. MarsTrace <asm_file>");
            System.exit(1);
        }

        String asmFile = args[0];
        File f = new File(asmFile);
        if (!f.exists()) {
            System.err.println("File not found: " + asmFile);
            System.exit(1);
        }

        // Initialize MARS in headless mode
        System.setProperty("java.awt.headless", "true");
        Globals.initialize(false);

        try {
            // Setup: read, tokenize, assemble
            ArrayList<String> filenames = new ArrayList<String>();
            filenames.add(f.getAbsolutePath());

            ArrayList<File> filesToAssemble =
                FilenameFinder.getFilenameList(filenames, FilenameFinder.MATCH_ALL_EXTENSIONS);

            MIPSprogram code = new MIPSprogram();
            ArrayList MIPSprogramsToAssemble =
                code.prepareFilesForAssembly(filesToAssemble, f.getAbsolutePath(), null);

            ErrorList warnings = code.assemble(MIPSprogramsToAssemble, true, false);
            if (warnings != null && warnings.warningsOccurred()) {
                // warnings are OK, continue
            }

            RegisterFile.initializeProgramCounter(false);

            // Step through and dump after each instruction
            int textStart = Memory.textBaseAddress;
            int textEnd   = Memory.textLimitAddress;

            while (true) {
                int pc = RegisterFile.getProgramCounter();

                // Stop when PC falls outside text segment
                if (pc < textStart || pc > textEnd) {
                    break;
                }

                // Dump PC
                System.out.println("pc: " + Binary.intToHexString(pc));

                // Dump instruction word
                try {
                    Integer instrObj = Globals.memory.getRawWordOrNull(pc);
                    if (instrObj == null) {
                        break;
                    }
                    System.out.println("instr: " + Binary.intToHexString(instrObj.intValue()));
                } catch (Exception e) {
                    break;
                }

                // Dump all 32 general-purpose registers
                for (int r = 0; r < 32; r++) {
                    int val = RegisterFile.getValue(r);
                    System.out.println("regfile" + r + ": " + Binary.intToHexString(val));
                }

                // Execute one step
                boolean done = code.simulateStepAtPC(null);
                if (done) {
                    break;
                }
            }
        } catch (ProcessingException e) {
            ErrorList errors = e.errors();
            if (errors != null) {
                System.err.println(errors.generateErrorAndWarningReport());
            }
            // ProcessingException during step is normal termination for some programs
            // (e.g., when they run off the end). Output the error to stderr as warning
            // but don't crash — the snapshots produced so far are valid.
        } catch (Exception e) {
            System.err.println("MarsTrace error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}

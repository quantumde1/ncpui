import std.stdio;
import std.process;

void main() {
    auto logFile = File("myapp_error.log", "w");
    auto pid = spawnProcess("myapp", stdin, stdout, logFile,
                            Config.retainStderr | Config.suppressConsole);
                            
    scope(exit)
    {
        auto exitCode = wait(pid);
        logFile.writeln("myapp exited with code ", exitCode);
        logFile.close();
    }
}
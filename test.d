import std.stdio;
import std.process;

void main() {
    auto logFile = File("myapp_error.log", "w");
    Config config = Config(Config.Flags.detached, null, null);
    auto pid = spawnProcess("myapp", stdin, stdout, logFile,
    config);
                            
    scope(exit)
    {
        auto exitCode = wait(pid);
        logFile.writeln("myapp exited with code ", exitCode);
        logFile.close();
    }
}
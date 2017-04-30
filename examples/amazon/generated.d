
        import trial.discovery;
        import trial.runner;
        import trial.interfaces;
        import trial.settings;
        import trial.reporters.result;
        import trial.reporters.spec;

    void main() {
        TestDiscovery testDiscovery;        testDiscovery.addModule!"amazontests";
        setupLifecycle(Settings(["spec", "result"]));
        runTests(testDiscovery, "");
    }

    version (unittest) shared static this()
    {
        import core.runtime;
        Runtime.moduleUnitTester = () => true;
    }
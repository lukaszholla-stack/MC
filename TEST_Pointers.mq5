//+------------------------------------------------------------------+
//|                                              TEST_Pointers.mq5 |
//|                                 Test wskaźników w MQL5          |
//+------------------------------------------------------------------+
#property strict

class CTestClass {
private:
    double m_value;
public:
    CTestClass() { m_value = 0; }
    double GetValue(int shift = 0) { return m_value + shift; }
    void SetValue(double val) { m_value = val; }
};

class CHolderClass {
private:
    CTestClass* m_testPointer;
public:
    CHolderClass() {
        m_testPointer = new CTestClass();
    }

    ~CHolderClass() {
        delete m_testPointer;
    }

    void TestMethod() {
        // Test operatora ->
        m_testPointer->SetValue(123.45);
        double val = m_testPointer->GetValue(10);
        Print("Wartość: ", val);
    }
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    CHolderClass holder;
    holder.TestMethod();
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Nothing
}
//+------------------------------------------------------------------+

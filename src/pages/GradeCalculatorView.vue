<template>
  <div class="grade-calculator">
    <main>
      <section class="hero">
        <div>
          <div class="eyebrow">Academic tools · 2026–27</div>
          <h1>Grade Calculator</h1>
          <div class="subtitle">
            Choose your level and course. Calculate estimated final scores, letter grades and grade
            points across Foundation, Diploma and Degree courses.
          </div>
        </div>
      </section>

      <div class="layout">
        <section class="panel">
          <div class="panel-head">
            <div>
              <h2>Select your course</h2>
              <div class="helper">
                The score fields update automatically for the selected course.
              </div>
            </div>
          </div>
          <div class="field">
            <label for="level">Level</label
            ><select id="level">
              <option value="foundation">Foundation</option>
              <option value="diploma">Diploma</option>
              <option value="degree">Degree</option>
            </select>
          </div>
          <div class="field">
            <label for="course">Course</label
            ><select id="course"></select>
          </div>

          <h2>Enter your scores</h2>
          <div class="note">
            <strong>Important note:</strong> If you were absent for an exam or quiz, leave that
            field blank. If you attended but scored zero, enter <strong>0</strong>. A blank
            mandatory component may result in a U grade. This tool estimates the score from the
            formulas supplied; it does not determine the official grade.
          </div>
          <div class="score-grid" id="regularFields">
            <div class="field">
              <label for="q1">Quiz 1 (Qz1)</label
              ><input
                id="q1"
                type="number"
                min="0"
                max="100"
                step="0.01"
                placeholder="Enter score (0–100)"
              />
            </div>
            <div class="field">
              <label for="q2">Quiz 2 (Qz2)</label
              ><input
                id="q2"
                type="number"
                min="0"
                max="100"
                step="0.01"
                placeholder="Enter score (0–100)"
              />
            </div>
            <div class="field">
              <label for="f">End-term exam (F)</label
              ><input
                id="f"
                type="number"
                min="0"
                max="100"
                step="0.01"
                placeholder="Enter score (0–100)"
              />
            </div>
            <div class="field bonus-field hidden" id="bonusWrap">
              <label for="bonus">Activity bonus (B)</label
              ><input
                id="bonus"
                type="number"
                min="0"
                max="6"
                step="0.01"
                placeholder="Enter bonus marks"
              /><small id="bonusHelp">Bonus is added only if the course is passed.</small>
            </div>
          </div>
          <div id="diplomaFields" class="hidden"></div>
          <div id="pythonFields" class="hidden">
            <div class="score-grid">
              <div class="field">
                <label for="pq1">Quiz 1 (Qz1)</label
                ><input
                  id="pq1"
                  type="number"
                  min="0"
                  max="100"
                  step=".01"
                  placeholder="Enter score (0–100)"
                />
              </div>
              <div class="field">
                <label for="pf">End-term exam (F)</label
                ><input
                  id="pf"
                  type="number"
                  min="0"
                  max="100"
                  step=".01"
                  placeholder="Enter score (0–100)"
                />
              </div>
              <div class="field">
                <label for="pe1">OPPE 1 (PE1)</label
                ><input
                  id="pe1"
                  type="number"
                  min="0"
                  max="100"
                  step=".01"
                  placeholder="Enter score (0–100)"
                />
              </div>
              <div class="field">
                <label for="pe2">OPPE 2 (PE2)</label
                ><input
                  id="pe2"
                  type="number"
                  min="0"
                  max="100"
                  step=".01"
                  placeholder="Enter score (0–100)"
                />
              </div>
            </div>
            <div class="field">
              <label for="weekly">Best 5 weekly assessments average (out of 100)</label
              ><input
                id="weekly"
                type="number"
                min="0"
                max="100"
                step=".01"
                placeholder="Enter best-5 average"
              />
            </div>
            <div class="field">
              <label>Did you complete the SCT?</label>
              <div class="exam-toggle">
                <label class="choice"
                  ><input type="radio" name="sct" value="yes" checked /><span>Yes</span></label
                ><label class="choice"
                  ><input type="radio" name="sct" value="no" /><span>No</span></label
                >
              </div>
            </div>
            <div class="field">
              <label>OPPE eligibility checks (weekly assessment scores)</label>
              <div class="score-grid">
                <div class="field">
                  <label for="a4">A1–A4 all ≥ 40?</label
                  ><select id="a4">
                    <option value="yes">Yes</option>
                    <option value="no">No</option>
                  </select>
                </div>
                <div class="field">
                  <label for="a8">A5–A8 all ≥ 40?</label
                  ><select id="a8">
                    <option value="yes">Yes</option>
                    <option value="no">No</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
          <button class="primary" id="calculate">Calculate course score</button>
          <div style="display: flex; justify-content: flex-end; margin-top: 10px">
            <button class="secondary" id="reset">Reset scores</button>
          </div>
        </section>
        <aside class="panel result-panel">
          <div class="panel-head">
            <div>
              <h2>Your calculation</h2>
              <div class="helper">Your result updates when you calculate.</div>
            </div>
          </div>
          <div class="result-top">
            <div class="result-label">Estimated final course score</div>
            <div class="score" id="score">— <span>/ 100</span></div>
            <div class="result-status" id="status">
              Enter your scores and select “Calculate course score”.
            </div>
          </div>
          <div class="grade-row">
            <div class="grade-letter" id="gradeLetter">—</div>
            <div class="grade-meta">
              <strong id="gradeName">Letter grade</strong
              ><small id="gradeDescription">Your estimated grade appears here.</small>
            </div>
            <div class="grade-points" id="gradePoints">
              —<small
                style="
                  display: block;
                  font-size: 9px;
                  font-weight: 500;
                  color: var(--ink-2);
                  text-align: center;
                "
                >points</small
              >
            </div>
          </div>
          <div class="result-line">
            <span>Course</span><strong id="resultCourse">Mathematics for Data Science 1</strong>
          </div>
          <div class="result-line">
            <span>Formula used</span><strong id="formulaName">Standard formula</strong>
          </div>
          <div class="result-line">
            <span>Bonus applied</span><strong id="bonusResult">0 marks</strong>
          </div>
          <div class="formula" id="formulaText">Select a course to view its formula.</div>
          <div id="eligibilityBlock" class="hidden">
            <div class="mini-title">Programming in Python eligibility</div>
            <div class="result-line"><span>OPPE 1</span><strong id="oppe1">—</strong></div>
            <div class="result-line"><span>OPPE 2</span><strong id="oppe2">—</strong></div>
            <div class="result-line">
              <span>End-term eligibility</span><strong id="endEligible">—</strong>
            </div>
          </div>
        </aside>
      </div>
    </main>
  </div>
</template>

<script setup>
import { onMounted } from 'vue';

onMounted(() => {
  const levelCourses = {
    foundation: [
      { id: 'ma1001', name: 'Mathematics for Data Science 1 (MA1001)', bonus: 0 },
      { id: 'hs1001', name: 'English 1 (HS1001)', bonus: 0 },
      { id: 'cs1001', name: 'Computational Thinking (CS1001)', bonus: 0 },
      { id: 'ma1002', name: 'Statistics for Data Science 1 (MA1002)', bonus: 5 },
      { id: 'ma1003', name: 'Mathematics for Data Science 2 (MA1003)', bonus: 6 },
      { id: 'hs1002', name: 'English 2 (HS1002)', bonus: 0 },
      { id: 'cs1002', name: 'Programming in Python (CS1002)', python: true, bonus: 0 },
      { id: 'ma1004', name: 'Statistics for Data Science 2 (MA1004)', bonus: 5 },
    ],
    diploma: [
      {
        id: 'd_ml_foundations',
        name: 'Machine Learning Foundations (CS2004)',
        type: 'mlf',
        fields: [
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['df', 'End-term exam (F)', 100],
          ['dweekly', 'Best 5 of first 7 weekly assignments average', 100],
          ['dbonus', 'Bonus marks (max 5)', 5],
        ],
      },
      {
        id: 'd_ml_techniques',
        name: 'Machine Learning Techniques (CS2007)',
        type: 'mlt',
        fields: [
          ['dgaa', 'GAA · first 10 weekly graded assignments', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['df', 'End-term exam (F)', 100],
          ['dallavg', 'Average of all assignments (bonus eligibility)', 100],
        ],
      },
      {
        id: 'd_ml_practice',
        name: 'Machine Learning Practice (CS2008)',
        type: 'mlp',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dop1', 'OPPE 1', 100],
          ['dop2', 'OPPE 2', 100],
          ['dka', 'KA · average of 3 Kaggle assignments', 100],
          ['df', 'End-term exam (F)', 100],
          ['dweekly', 'Best 5 of 7 weekly assessments average', 100],
        ],
      },
      {
        id: 'd_bdm',
        name: 'Business Data Management (MS2001)',
        type: 'bdm',
        fields: [
          ['dgaa', 'GAA · first 9 weekly assignments', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['df', 'End-term exam (F)', 100],
        ],
      },
      {
        id: 'd_ba',
        name: 'Business Analytics (MS2002)',
        type: 'ba',
        fields: [
          ['dq1', 'Quiz 1 (out of 20)', 20],
          ['dq2', 'Quiz 2 (out of 20)', 20],
          ['da1', 'Assignment 1 (out of 10)', 10],
          ['da2', 'Assignment 2 (out of 10)', 10],
          ['da3', 'Assignment 3 (out of 10)', 10],
          ['df', 'End-term exam raw marks (out of 45; capped at 40)', 45],
        ],
      },
      {
        id: 'd_tds',
        name: 'Tools in Data Science (SE2002)',
        type: 'tds',
        fields: [
          ['dgaa', 'GAA · best 7 of 9 weekly assignments', 100],
          ['droe', 'ROE score', 100],
          ['dp1', 'Project 1 (P1)', 100],
          ['dp2', 'Project 2 (P2)', 100],
          ['df', 'End-term exam (F)', 100],
          ['dweekly', 'Best 2 of first 4 GAs average (eligibility)', 100],
        ],
      },
      {
        id: 'd_pdsa',
        name: 'Programming, Data Structures and Algorithms using Python (CS2002)',
        type: 'pdsa',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['dop', 'Online proctored exam (OP)', 100],
          ['df', 'End-term exam (F)', 100],
          ['dweekly', 'Best 5 of first 7 weekly assessments average', 100],
        ],
      },
      {
        id: 'd_dbms',
        name: 'Database Management System (CS2001)',
        type: 'dbms',
        fields: [
          ['dgaa2', 'GAA2 · average of week 2 and 3 SQL assignments', 100],
          ['dgaa3', 'GAA3 · week 7 programming assignment', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['dop', 'OPPE score', 100],
          ['df', 'End-term exam (F)', 100],
        ],
      },
      {
        id: 'd_appdev1',
        name: 'Application Development 1 (CS2003)',
        type: 'appdev1',
        fields: [
          ['dgla', 'GLA · weighted lab assignment score', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['df', 'End-term exam (F)', 100],
        ],
      },
      {
        id: 'd_java',
        name: 'Programming Concepts using Java (CS2005)',
        type: 'java',
        fields: [
          ['dgaa', 'GAA · best 6 of 7 weeks programming assignments', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['dpe1', 'OPPE 1 (PE1)', 100],
          ['dpe2', 'OPPE 2 (PE2)', 100],
          ['df', 'End-term exam (F)', 100],
        ],
      },
      {
        id: 'd_syscmd',
        name: 'System Commands (SE2001)',
        type: 'syscmd',
        fields: [
          ['dgaa', 'GAA · best 9 of 10 weekly assignments', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dop', 'OPPE score', 100],
          ['dbpta', 'BPT average (BPTA)', 100],
          ['df', 'End-term exam (F)', 100],
        ],
      },
      {
        id: 'd_appdev2',
        name: 'Application Development 2 (CS2006)',
        type: 'appdev2',
        fields: [
          ['dgaa', 'GAA · average of week 1 and 2 programming assignments', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['df', 'End-term exam (F)', 100],
        ],
      },
      {
        id: 'd_genai',
        name: 'Introduction to Deep Learning and Generative AI (DA2001)',
        type: 'genai',
        fields: [
          ['dgaa', 'GAA · first 9 weekly assignments', 100],
          ['dq1', 'Quiz 1 (Qz1)', 100],
          ['dq2', 'Quiz 2 (Qz2)', 100],
          ['df', 'End-term exam (F)', 100],
          ['dnppe1', 'NPPE 1', 100],
          ['dnppe2', 'NPPE 2', 100],
        ],
      },
    ],
    degree: [
      {
        name: 'Software Testing (CS3002)',
        type: 'st',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Software Engineering (CS3001)',
        type: 'se',
        fields: [
          ['dgaa', 'GAA · 10 weekly assignments', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dgp1', 'Group project milestones 1–2 (GP1)', 100],
          ['dgp2', 'Group project milestones 3–5 (GP2)', 100],
          ['dpp', 'Project presentation (PP)', 100],
          ['dcp', 'Course participation (CP)', 100],
        ],
      },
      {
        name: 'Deep Learning (CS3004)',
        type: 'dl',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dbonus', 'Programming activity bonus (max 5)', 5],
        ],
      },
      {
        name: 'AI: Search Methods for Problem Solving (CS3003)',
        type: 'ai',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dbonus', 'Programming assignment bonus (max 5)', 5],
        ],
      },
      {
        name: 'Strategies for Professional Growth (GN3001)',
        type: 'spg',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dgp', 'Group project (GP)', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Programming in C (CS3005)',
        type: 'c',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dop1', 'OPPE 1', 100],
          ['dop2', 'OPPE 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Deep Learning for CV (DA5006)',
        type: 'dlcv',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dbonus', 'Optional project bonus (max 5)', 5],
        ],
      },
      {
        name: 'Large Language Models (DA5004)',
        type: 'llm',
        fields: [
          ['dgaa', 'GAA · all 7 assignments till week 9', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dbonus', 'Programming assignment bonus (max 5)', 5],
        ],
      },
      {
        name: 'Deep Learning Practice (DA5013)',
        type: 'dlp',
        fields: [
          ['dgaa', 'GAA · best 10 of 11 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['dq3', 'Quiz 3', 100],
          ['dnppe1', 'NPPE 1', 100],
          ['dnppe2', 'NPPE 2', 100],
          ['dnppe3', 'NPPE 3', 100],
          ['dviva', 'Viva', 100],
        ],
      },
      {
        name: 'Data Science and AI Lab (DA4001)',
        type: 'dsailab',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dq2', 'Quiz 2', 100],
          ['dp', 'Project + milestones/presentation', 100],
          ['dviva', 'Viva', 100],
          ['dbonus', 'Bonus (max 5)', 5],
        ],
      },
      {
        name: 'Application Development Lab (CS4010)',
        type: 'adlab',
        fields: [
          ['dgaa', 'Weekly assignment average · first 10 weeks', 100],
          ['dq2', 'Quiz 2', 100],
          ['dp', 'Project viva component (out of 50)', 50],
        ],
      },
      {
        name: 'Big Data and Biological Networks (BT4002)',
        type: 'bdbn',
        fields: [
          ['dgaa', 'GAA · best 8 of first 9 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Industry 4.0 (MS4001)',
        type: 'industry',
        fields: [
          ['dq1', 'Quiz 1 (out of 7.5)', 7.5],
          ['dq2', 'Quiz 2 (out of 7.5)', 7.5],
          ['dgame', 'Yield management game (out of 5)', 5],
          ['da1', 'Assignment 1 (out of 20)', 20],
          ['da2', 'Assignment 2 (out of 20)', 20],
          ['da3', 'Assignment 3 (out of 20)', 20],
          ['df', 'End-term exam raw marks (capped at 40)', 45],
          ['dp', 'Project (out of 10)', 10],
        ],
      },
      {
        name: 'Mathematical Thinking (MA2001)',
        type: 'maththink',
        fields: [
          ['dgaa', 'GAA · first 10 weekly assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'MLOps (DA5014)',
        type: 'mlops',
        fields: [
          ['dgaa', 'GAA · best 9 of 11 assignments', 100],
          ['df', 'End-term exam', 100],
          ['dop1', 'OPPE 1', 100],
          ['dop2', 'OPPE 2', 100],
          ['dbonus', 'Active participation bonus (max 5)', 5],
        ],
      },
      {
        name: 'Mathematical Foundations of Generative AI (DA5002)',
        type: 'mathgen',
        fields: [
          ['dgaa', 'GAA · best 10 weekly assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dnppe', 'NPPE', 100],
        ],
      },
      {
        name: 'Speech Technology (EE4001)',
        type: 'speech',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['dviva', 'Viva', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Design Thinking for Data-Driven App Development (MS4002)',
        type: 'design',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq2', 'Quiz 2', 100],
          ['dgp1', 'Group project GP1', 100],
          ['dgp2', 'Group project GP2', 100],
          ['dgp3', 'Group project GP3', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Financial Forensics (MS4003)',
        type: 'financefor',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dgp', 'Group project (GP1)', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Introduction to Big Data (DA5001)',
        type: 'bigdata',
        fields: [
          ['dgaa', 'GAA · best 6 of 9 assignments', 100],
          ['df', 'End-term exam', 100],
          ['dop1', 'OPPE 1', 100],
          ['dop2', 'OPPE 2', 100],
          ['dbonus', 'Live session bonus (max 5)', 5],
        ],
      },
      {
        name: 'Linear Models with Applications (MA3015)',
        type: 'linear',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['dp', 'Project', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Special Topics in ML — Reinforcement Learning (DA5007)',
        type: 'rl',
        fields: [
          ['dgaa', 'Autograded GAA', 100],
          ['dgpa', 'Graded programming assignments (GPA)', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dbonus', 'Instructor bonus (max 5)', 5],
        ],
      },
      {
        name: 'Corporate Finance (MS3034)',
        type: 'corpfin',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Computer Networks (CS4024)',
        type: 'networks',
        fields: [
          ['dgaa', 'GAA · 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dp', 'Programming assignment', 100],
        ],
      },
      {
        name: 'Computer Systems Design (CS3031)',
        type: 'csdesign',
        fields: [
          ['dgaa', 'GAA · 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dp', 'CircuitVerse assignment', 100],
        ],
      },
      {
        name: 'Game Theory and Strategy (MS4023)',
        type: 'gametheory',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Algorithms for Data Science (DA5003)',
        type: 'ads',
        fields: [
          ['dgaa', 'GAA · six assignments average', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dbonus', 'Programming assignment bonus (max 5)', 5],
        ],
      },
      {
        name: 'Compiler Design (CS4032)',
        type: 'compiler',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Sequential Decision Making (DA6004)',
        type: 'seq',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dbonus', 'Programming assignment bonus (max 5)', 5],
        ],
      },
      {
        name: 'Operating Systems (CS4022)',
        type: 'os',
        fields: [
          ['dgaa', 'GAA · 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Discrete Mathematics (MA3001)',
        type: 'discrete',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Digital IC Design (EE5102)',
        type: 'icdesign',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
          ['dp', 'Course project', 100],
        ],
      },
      {
        name: 'Electronic Testing and Measurement (EE2105)',
        type: 'etm',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Communication Systems (EE4103)',
        type: 'comms',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Digital System Design (EE2103)',
        type: 'dsd',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
      {
        name: 'Computer Organization (EE2106)',
        type: 'org',
        fields: [
          ['dgaa', 'GAA · first 10 assignments', 100],
          ['dq1', 'Quiz 1', 100],
          ['dq2', 'Quiz 2', 100],
          ['df', 'End-term exam', 100],
        ],
      },
    ].map((c, i) => ({ id: 'degree_' + (i + 1), ...c })),
  };
  let courses = {};
  const $ = (id) => document.getElementById(id);
  const standardFormula = 'T = max(0.6F + 0.3 max(Qz1,Qz2), 0.45F + 0.25Qz1 + 0.3Qz2)';
  const bonusFormula = 'T = min(100, max(0.6F + 0.3 max(Qz1,Qz2), 0.45F + 0.25Qz1 + 0.3Qz2) + B)';
  const pythonFormula = 'T = 0.15Qz1 + 0.4F + 0.25 max(PE1,PE2) + 0.2 min(PE1,PE2)';
  function val(id) {
    const el = $(id);
    if (!el) return null;
    const s = el.value.trim();
    return s === '' ? null : Number(s);
  }
  function valid(id, min = 0, max = 100) {
    const n = val(id);
    return n === null || (Number.isFinite(n) && n >= min && n <= max);
  }
  function read(id) {
    return val(id);
  }
  function populateCourses() {
    const level = $('level').value,
      list = levelCourses[level];
    $('course').innerHTML = '';
    list.forEach((item) => {
      courses[item.id] = item;
      const option = document.createElement('option');
      option.value = item.id;
      option.textContent = item.name;
      $('course').appendChild(option);
    });
    showCourse();
  }
  function renderDiplomaFields(c) {
    const host = $('diplomaFields');
    host.innerHTML = '';
    if (!c.fields) return;
    const grid = document.createElement('div');
    grid.className = 'score-grid';
    c.fields.forEach(([id, label, max]) => {
      const field = document.createElement('div');
      field.className = 'field';
      const lab = document.createElement('label');
      lab.htmlFor = id;
      lab.textContent = label;
      const input = document.createElement('input');
      input.id = id;
      input.type = 'number';
      input.min = '0';
      input.max = String(max);
      input.step = '.01';
      input.placeholder = `Enter score (0–${max})`;
      field.append(lab, input);
      grid.appendChild(field);
    });
    host.appendChild(grid);
    const note = document.createElement('div');
    note.className = 'helper';
    note.style.margin = '0 0 14px';
    note.textContent =
      'Enter component scores on the scales shown. Fields for eligibility are separate from the weighted score where applicable.';
    host.appendChild(note);
  }
  function showCourse() {
    const level = $('level').value,
      c = courses[$('course').value] || levelCourses[level][0];
    const isFoundation = level === 'foundation',
      isDiploma = level === 'diploma',
      isDegree = level === 'degree',
      isPy = !!c.python;
    $('regularFields').classList.toggle('hidden', !isFoundation || isPy);
    $('pythonFields').classList.toggle('hidden', !isFoundation || !isPy);
    $('diplomaFields').classList.toggle('hidden', !(isDiploma || isDegree));
    if (isDiploma || isDegree) renderDiplomaFields(c);
    $('bonusWrap').classList.toggle('hidden', !isFoundation || !c.bonus);
    $('calculate').disabled = !(isFoundation || isDiploma || isDegree);
    $('calculate').style.opacity = isFoundation || isDiploma || isDegree ? '1' : '.55';
    $('calculate').style.cursor = isFoundation || isDiploma || isDegree ? 'pointer' : 'not-allowed';
    if (c.bonus && isFoundation) {
      $('bonus').max = c.bonus;
      $('bonus').placeholder = `Enter bonus (max ${c.bonus})`;
      $('bonusHelp').textContent =
        `Maximum ${c.bonus} bonus marks; applied only if the base course is passing.`;
    }
    $('resultCourse').textContent = c.name;
    $('formulaName').textContent = isDegree
      ? 'Degree course formula'
      : isDiploma
        ? 'Diploma course formula'
        : isPy
          ? 'Python weighted formula'
          : c.bonus
            ? 'Formula + activity bonus'
            : 'Standard formula';
    $('formulaText').textContent = isDegree
      ? degreeFormulaText(c.type)
      : isDiploma
        ? diplomaFormulaText(c.type)
        : isPy
          ? pythonFormula
          : c.bonus
            ? bonusFormula
            : standardFormula;
    $('eligibilityBlock').classList.toggle('hidden', !isFoundation || !isPy);
    $('score').innerHTML = '— <span>/ 100</span>';
    $('status').textContent = isFoundation
      ? 'Enter your scores and select “Calculate course score”.'
      : isDiploma
        ? 'Enter the component scores for this Diploma course.'
        : 'Enter the component scores for this Degree course.';
    $('bonusResult').textContent = '0 marks';
    $('gradeLetter').textContent = '—';
    $('gradeName').textContent = 'Letter grade';
    $('gradeDescription').textContent = 'Your estimated grade appears here.';
    $('gradePoints').innerHTML =
      '—<small style="display:block;font-size:9px;font-weight:500;color:var(--ink-2);text-align:center">points</small>';
  }
  function diplomaFormulaText(type) {
    const f = {
      mlf: 'T = max(0.6F + 0.3 max(Qz1,Qz2), 0.45F + 0.25Qz1 + 0.3Qz2) + BONUS (max 5)',
      mlt: 'T = 0.05 GAA + max(0.6F + 0.25 max(Qz1,Qz2), 0.4F + 0.25Qz1 + 0.3Qz2) [+3 if all-assignment average ≥40]',
      mlp: 'T = 0.05 GAA + 0.40F + 0.20 OPPE1 + 0.20 OPPE2 + 0.15 KA',
      bdm: 'T = 0.05 GAA + max(0.6F + 0.25 max(Qz1,Qz2), 0.4F + 0.25Qz1 + 0.3Qz2)',
      ba: 'Qz = 2(0.7 max(Qz1,Qz2) + 0.3 min(Qz1,Qz2)); A = best 2 assignments; T = Qz + A + capped F',
      tds: 'T = 0.2 GAA + 0.2 ROE + 0.2 P1 + 0.2 P2 + 0.2 F',
      pdsa: 'T = 0.05 GAA + 0.2 OP + 0.45F + max(0.2 max(Qz1,Qz2), 0.1Qz1 + 0.2Qz2)',
      dbms: 'T = 0.03 GAA2 + 0.02 GAA3 + 0.2 OPPE + 0.45F + max(0.2 max(Qz1,Qz2), 0.1Qz1 + 0.2Qz2)',
      appdev1: 'T = 0.05 GLA + max(0.6F + 0.25 max(Qz1,Qz2), 0.4F + 0.25Qz1 + 0.3Qz2)',
      java: 'T = 0.05 GAA + 0.2 max(PE1,PE2) + 0.45F + max(0.2 max(Qz1,Qz2), 0.1Qz1 + 0.2Qz2) + 0.1 min(PE1,PE2)',
      syscmd: 'T = 0.05 GAA + 0.25 Qz1 + 0.3 OPPE + 0.3F + 0.1 BPTA',
      appdev2: 'T = 0.05 GAA + max(0.6F + 0.25 max(Qz1,Qz2), 0.4F + 0.25Qz1 + 0.3Qz2)',
      genai: 'T = 0.1 GAA + 0.2 Qz1 + 0.2 Qz2 + 0.25F + 0.1 NPPE1 + 0.15 NPPE2',
    };
    return f[type] || 'Formula not available in the provided course document.';
  }
  function gradeAndDisplay(total, status, bonusText = 'Not applicable') {
    total = Math.max(0, Math.min(100, total));
    $('score').innerHTML = `${total.toFixed(2)} <span>/ 100</span>`;
    const grade =
      total < 40
        ? { letter: 'U', points: 0, name: 'Fail', desc: 'Below the stated pass mark of 40.' }
        : total >= 90
          ? { letter: 'S', points: 10, name: 'Outstanding', desc: 'Estimated band: 90–100.' }
          : total >= 80
            ? { letter: 'A', points: 9, name: 'Excellent', desc: 'Estimated band: 80–89.99.' }
            : total >= 70
              ? { letter: 'B', points: 8, name: 'Very good', desc: 'Estimated band: 70–79.99.' }
              : total >= 60
                ? { letter: 'C', points: 7, name: 'Good', desc: 'Estimated band: 60–69.99.' }
                : total >= 50
                  ? {
                      letter: 'D',
                      points: 6,
                      name: 'Satisfactory',
                      desc: 'Estimated band: 50–59.99.',
                    }
                  : {
                      letter: 'E',
                      points: 4,
                      name: 'Marginal pass',
                      desc: 'Estimated band: 40–49.99.',
                    };
    $('gradeLetter').textContent = grade.letter;
    $('gradeName').textContent = `${grade.letter} grade · ${grade.name}`;
    $('gradeDescription').textContent = grade.desc;
    $('gradePoints').innerHTML =
      `${grade.points}<small style="display:block;font-size:9px;font-weight:500;color:var(--ink-2);text-align:center">points</small>`;
    $('status').textContent = status;
    $('bonusResult').textContent = bonusText;
  }
  function calculateDiploma(c) {
    const fields = c.fields.map((x) => x[0]);
    for (const id of fields) {
      if (!valid(id, 0, Number($(id).max))) {
        alert(`Please enter a valid score for ${$(id).previousElementSibling.textContent}.`);
        return;
      }
    }
    const v = (id) => read(id);
    const need = (ids) => ids.every((id) => v(id) !== null);
    let T = 0,
      status = 'Calculated from the course formula in the provided Diploma document.',
      bonus = 'Not applicable';
    const q1 = v('dq1') ?? 0,
      q2 = v('dq2') ?? 0,
      f = v('df') ?? 0,
      qa = Math.max(q1, q2);
    const qAlt = Math.max(0.6 * f + 0.25 * qa, 0.4 * f + 0.25 * q1 + 0.3 * q2);
    switch (c.type) {
      case 'mlf':
        if (!need(['df', 'dweekly'])) {
          alert(
            'Enter End-term score and best-5 weekly average to calculate. Quiz not attempted can be entered as 0.'
          );
          return;
        }
        T = Math.max(0.6 * f + 0.3 * qa, 0.45 * f + 0.25 * q1 + 0.3 * q2) + (v('dbonus') || 0);
        T = Math.min(100, T);
        bonus = `${(v('dbonus') || 0).toFixed(2)} entered (max 5; instructor bonus rules apply)`;
        status =
          v('dweekly') >= 40
            ? 'Eligibility weekly-average criterion met; quiz attendance must also be confirmed.'
            : 'Weekly best-5 average is below 40; final-exam eligibility criterion not met.';
        break;
      case 'mlt':
        if (!need(['dgaa', 'df', 'dallavg'])) {
          alert(
            'Enter GAA, End-term score and all-assignment average. Quiz not attempted can be entered as 0.'
          );
          return;
        }
        T = 0.05 * v('dgaa') + qAlt;
        if (v('dallavg') >= 40) {
          T += 3;
          bonus = '3 marks added (all-assignment average ≥40)';
        } else bonus = '0 marks (all-assignment average below 40)';
        break;
      case 'mlp':
        if (!need(['dgaa', 'dop1', 'dop2', 'dka', 'df', 'dweekly'])) {
          alert('Fill all MLP score fields.');
          return;
        }
        T = 0.05 * v('dgaa') + 0.4 * f + 0.2 * v('dop1') + 0.2 * v('dop2') + 0.15 * v('dka');
        status =
          v('dweekly') >= 40 && (v('dop1') >= 40 || v('dop2') >= 40)
            ? 'Score calculated; grade eligibility also requires end-term attendance and at least one programming exam score ≥40.'
            : 'Check eligibility: best-5 weekly average must be ≥40 and at least one programming exam score must be ≥40.';
        break;
      case 'bdm':
        if (!need(['dgaa', 'df'])) {
          alert('Enter GAA and End-term score. Quiz not attempted can be entered as 0.');
          return;
        }
        T = 0.05 * v('dgaa') + qAlt;
        break;
      case 'ba':
        if (!need(['dq1', 'dq2', 'da1', 'da2', 'da3', 'df'])) {
          alert('Fill all Business Analytics components.');
          return;
        }
        const Q = 2 * (0.7 * Math.max(q1, q2) + 0.3 * Math.min(q1, q2));
        const A = [v('da1'), v('da2'), v('da3')]
          .sort((a, b) => b - a)
          .slice(0, 2)
          .reduce((a, b) => a + b, 0);
        const cappedF = Math.min(40, f);
        T = Q + A + cappedF;
        status =
          f < 10
            ? 'U-grade condition: End-term raw score is below 10/40 required.'
            : T < 40
              ? 'U-grade condition: total score is below 40/100.'
              : 'Score calculated. Passing requires F ≥10/40 and total T ≥40/100.';
        break;
      case 'tds':
        if (!need(['dgaa', 'droe', 'dp1', 'dp2', 'df', 'dweekly'])) {
          alert('Fill all TDS score fields.');
          return;
        }
        T = 0.2 * (v('dgaa') + v('droe') + v('dp1') + v('dp2') + f);
        status =
          v('dweekly') >= 40
            ? 'Score calculated; best-2-of-first-4 GAs criterion is met.'
            : 'End-term eligibility criterion (best 2 of first 4 GA average ≥40) is not met.';
        break;
      case 'pdsa':
        if (!need(['dgaa', 'dop', 'df', 'dweekly'])) {
          alert(
            'Enter GAA, OP score, End-term and weekly best-5 average. Quiz not attempted can be entered as 0.'
          );
          return;
        }
        T = 0.05 * v('dgaa') + 0.2 * v('dop') + 0.45 * f + Math.max(0.2 * qa, 0.1 * q1 + 0.2 * q2);
        status =
          v('dweekly') >= 40
            ? 'Score calculated; end-term eligibility also requires attendance in at least one quiz.'
            : 'Best-5 weekly average below 40; end-term eligibility criterion not met.';
        break;
      case 'dbms':
        if (!need(['dgaa2', 'dgaa3', 'dop', 'df'])) {
          alert(
            'Enter GAA2, GAA3, OPPE and End-term score. Quiz not attempted can be entered as 0.'
          );
          return;
        }
        T =
          0.03 * v('dgaa2') +
          0.02 * v('dgaa3') +
          0.2 * v('dop') +
          0.45 * f +
          Math.max(0.2 * qa, 0.1 * q1 + 0.2 * q2);
        status =
          v('dop') < 35
            ? 'Eligibility warning: course grade requires OPPE ≥35/100 and the Python–DB connectivity question correct.'
            : 'Score calculated; course grade additionally requires Python–DB connectivity question correct and end-term attendance.';
        break;
      case 'appdev1':
        if (!need(['dgla', 'df'])) {
          alert('Enter GLA and End-term score. Quiz not attempted can be entered as 0.');
          return;
        }
        T = 0.05 * v('dgla') + qAlt;
        break;
      case 'java':
        if (!need(['dgaa', 'dpe1', 'dpe2', 'df'])) {
          alert(
            'Enter GAA, both OPPE scores and End-term. Quiz not attempted can be entered as 0.'
          );
          return;
        }
        T =
          0.05 * v('dgaa') +
          0.2 * Math.max(v('dpe1'), v('dpe2')) +
          0.45 * f +
          Math.max(0.2 * qa, 0.1 * q1 + 0.2 * q2) +
          0.1 * Math.min(v('dpe1'), v('dpe2'));
        status =
          v('dpe1') >= 30 || v('dpe2') >= 30
            ? 'Score calculated; grade eligibility requires attending end-term and at least one programming exam score ≥30%.'
            : 'Eligibility warning: at least one programming exam must be ≥30% to obtain the course grade.';
        break;
      case 'syscmd':
        if (!need(['dgaa', 'dop', 'dbpta', 'df'])) {
          alert(
            'Enter GAA, OPPE, BPT average and End-term. Quiz not attempted can be entered as 0.'
          );
          return;
        }
        T = 0.05 * v('dgaa') + 0.25 * q1 + 0.3 * v('dop') + 0.3 * f + 0.1 * v('dbpta');
        status =
          v('dop') >= 40
            ? 'Score calculated; grade eligibility requires end-term attendance and OPPE ≥40/100.'
            : 'Eligibility warning: OPPE score must be at least 40/100 for the course grade.';
        break;
      case 'appdev2':
        if (!need(['dgaa', 'df'])) {
          alert('Enter GAA and End-term. Quiz not attempted can be entered as 0.');
          return;
        }
        T = 0.05 * v('dgaa') + qAlt;
        break;
      case 'genai':
        if (!need(['dgaa', 'dq1', 'dq2', 'df', 'dnppe1', 'dnppe2'])) {
          alert('Fill all Deep Learning and Generative AI components.');
          return;
        }
        T =
          0.1 * v('dgaa') + 0.2 * q1 + 0.2 * q2 + 0.25 * f + 0.1 * v('dnppe1') + 0.15 * v('dnppe2');
        break;
    }
    gradeAndDisplay(T, status, bonus);
  }

  function degreeFormulaText(type) {
    const map = {
      st: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2',
      se: 'T = 0.05GAA + 0.2Qz2 + 0.4F + 0.1GP1 + 0.1GP2 + 0.1PP + 0.05CP',
      dl: 'T = 0.05GAA + 0.25Qz1 + 0.25Qz2 + 0.45F',
      ai: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2 + bonus',
      spg: 'T = 0.10GAA + 0.25GP + 0.30Qz2 + 0.35F',
      c: 'T = 0.10GAA + 0.20Qz1 + 0.20OPPE1 + 0.20OPPE2 + 0.30F',
      dlcv: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2 + bonus',
      llm: 'T = 0.05GAA + 0.35F + 0.3Qz1 + 0.3Qz2 + bonus',
      dlp: 'T = 0.05GAA + 0.15Qz1 + 0.15Qz2 + 0.15Qz3 + 0.25×average(NPPE1–3) + 0.25Viva',
      dsailab: 'T = 0.05GAA + 0.25Quiz + 0.4P + 0.3V + bonus',
      adlab: 'T = 0.2Quiz2 + 0.3GAA + 0.5 Project Viva',
      bdbn: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2',
      industry: 'T = Quiz marks + game + best 2 assignments + capped F + project',
      maththink: 'T = 0.1GAA + max(0.6F + 0.2max(Qz1,Qz2), 0.4F + 0.2Qz1 + 0.3Qz2)',
      mlops: 'T = 0.2GAA + 0.3F + 0.25OPPE1 + 0.25OPPE2 + bonus (cap 100)',
      mathgen: 'T = 0.05GAA + 0.4F + 0.2Qz1 + 0.2Qz2 + 0.15NPPE',
      speech: 'T = 0.15GAA + 0.15Viva + 0.3F + 0.2Qz1 + 0.2Qz2',
      design: 'T = 0.1GAA + 0.1GP1 + 0.1GP2 + 0.2GP3 + 0.2Qz2 + 0.3F',
      financefor: 'T = 0.1GAA + 0.25Qz1 + 0.3GP1 + 0.35F',
      bigdata: 'T = 0.1GAA + 0.3F + 0.2OPPE1 + 0.4OPPE2 + bonus (cap 100)',
      linear: 'T = 0.1GAA + 0.25P + max(0.35F + 0.2max(Qz1,Qz2), 0.35F + 0.15Qz1 + 0.15Qz2)',
      rl: 'T = 0.05GAA + 0.25GPA + 0.2Qz1 + 0.2Qz2 + 0.3F + bonus',
      corpfin: 'T = 0.1GAA + 0.4F + 0.2Qz1 + 0.3Qz2',
      networks: 'T = 0.1GAA + 0.3F + 0.25Qz1 + 0.25Qz2 + 0.1Programming assignment',
      csdesign: 'T = 0.1GAA + 0.4F + 0.2Qz1 + 0.25Qz2 + 0.05CircuitVerse',
      gametheory: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2',
      ads: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2 + bonus',
      compiler: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2',
      seq: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2 + bonus',
      os: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2',
      discrete: 'T = 0.1GAA + 0.4F + 0.25Qz1 + 0.25Qz2',
      icdesign: 'T = 0.1GAA + 0.3P + max(0.3F + 0.2max(Qz1,Qz2), 0.3F + 0.15Qz1 + 0.15Qz2)',
      etm: 'T = 0.1GAA + max(0.6F + 0.2max(Qz1,Qz2), 0.5F + 0.2Qz1 + 0.2Qz2) (tentative)',
      comms: 'T = 0.1GAA + max(0.6F + 0.2max(Qz1,Qz2), 0.4F + 0.2Qz1 + 0.3Qz2)',
      dsd: 'T = 0.05GAA + max(0.6F + 0.25max(Qz1,Qz2), 0.5F + 0.2Qz1 + 0.25Qz2)',
      org: 'T = 0.05GAA + max(0.6F + 0.25max(Qz1,Qz2), 0.5F + 0.2Qz1 + 0.25Qz2)',
    };
    return map[type] || 'See the supplied degree course document.';
  }
  function calculateDegree(c) {
    for (const [id, label, max] of c.fields) {
      if (!valid(id, 0, Number($(id).max))) {
        alert('Please enter valid scores for all fields (within each field maximum).');
        return;
      }
    }
    const v = (id) => read(id) ?? 0,
      need = (ids) => ids.every((id) => read(id) !== null);
    const q1 = v('dq1'),
      q2 = v('dq2'),
      f = v('df'),
      gaa = v('dgaa');
    const qmax = Math.max(q1, q2),
      standard = Math.max(0.6 * f + 0.2 * qmax, 0.4 * f + 0.2 * q1 + 0.3 * q2);
    let T = 0,
      bonusText = 'Not applicable',
      status = 'Calculated using the formula listed in the supplied Degree-level document.';
    switch (c.type) {
      case 'st':
        T = 0.1 * gaa + 0.4 * f + 0.25 * q1 + 0.25 * q2;
        break;
      case 'se':
        T =
          0.05 * gaa +
          0.2 * q2 +
          0.4 * f +
          0.1 * v('dgp1') +
          0.1 * v('dgp2') +
          0.1 * v('dpp') +
          0.05 * v('dcp');
        status =
          'Course grade also requires all group-project milestones, project score > 0, and end-term attendance.';
        break;
      case 'dl':
        T = 0.05 * gaa + 0.25 * q1 + 0.25 * q2 + 0.45 * f;
        T += v('dbonus');
        bonusText = `${v('dbonus')} entered (max 5; programming activity average)`;
        break;
      case 'ai':
        T = 0.1 * gaa + 0.4 * f + 0.25 * q1 + 0.25 * q2 + (f >= 40 ? v('dbonus') : 0);
        bonusText =
          f >= 40
            ? `${v('dbonus')} applied if course passed`
            : 'Bonus not applied: base score must pass';
        break;
      case 'spg':
        T = 0.1 * gaa + 0.25 * v('dgp') + 0.3 * q2 + 0.35 * f;
        break;
      case 'c':
        T = 0.1 * gaa + 0.2 * q1 + 0.2 * v('dop1') + 0.2 * v('dop2') + 0.3 * f;
        status =
          v('dop1') >= 40 || v('dop2') >= 40
            ? 'Score calculated; course grade requires end-term attendance and at least one OPPE ≥40.'
            : 'Eligibility warning: one OPPE must be ≥40 for the course grade.';
        break;
      case 'dlcv':
        T = 0.1 * gaa + 0.4 * f + 0.25 * q1 + 0.25 * q2 + v('dbonus');
        bonusText = `${v('dbonus')} entered (max 5; optional project)`;
        break;
      case 'llm':
        T = 0.05 * gaa + 0.35 * f + 0.3 * q1 + 0.3 * q2 + (f >= 40 ? v('dbonus') : 0);
        bonusText =
          f >= 40
            ? `${v('dbonus')} entered (max 5; if course passed)`
            : 'Bonus not applied unless course passed';
        break;
      case 'dlp':
        T =
          0.05 * gaa +
          0.15 * q1 +
          0.15 * q2 +
          0.15 * v('dq3') +
          0.25 * ((v('dnppe1') + v('dnppe2') + v('dnppe3')) / 3) +
          0.25 * v('dviva');
        status =
          'Course grade eligibility requires Viva ≥40%; if NPPE submissions are missing, viva eligibility may be affected.';
        break;
      case 'dsailab':
        T = 0.05 * gaa + 0.25 * q2 + 0.4 * v('dp') + 0.3 * v('dviva') + v('dbonus');
        bonusText = `${v('dbonus')} entered (max 5)`;
        break;
      case 'adlab':
        T = 0.2 * q2 + 0.3 * gaa + 0.5 * v('dp');
        status =
          'Course grade requires project viva score ≥25/50 and attendance; other eligibility criteria apply.';
        break;
      case 'bdbn':
        T = 0.1 * gaa + 0.4 * f + 0.25 * q1 + 0.25 * q2;
        break;
      case 'industry':
        T =
          q1 +
          q2 +
          v('dgame') +
          [v('da1'), v('da2'), v('da3')]
            .sort((a, b) => b - a)
            .slice(0, 2)
            .reduce((a, b) => a + b, 0) +
          Math.min(40, f) +
          v('dp');
        status =
          'Enter quiz, game, assignment, project and end-term marks on the scales shown. Document lists total as 100.';
        break;
      case 'maththink':
        T = 0.1 * gaa + Math.max(0.6 * f + 0.2 * qmax, 0.4 * f + 0.2 * q1 + 0.3 * q2);
        break;
      case 'mlops':
        T = Math.min(100, 0.2 * gaa + 0.3 * f + 0.25 * v('dop1') + 0.25 * v('dop2') + v('dbonus'));
        bonusText = `${v('dbonus')} entered (max 5; total capped at 100)`;
        break;
      case 'mathgen':
        T = 0.05 * gaa + 0.4 * f + 0.2 * q1 + 0.2 * q2 + 0.15 * v('dnppe');
        break;
      case 'speech':
        T = 0.15 * gaa + 0.15 * v('dviva') + 0.3 * f + 0.2 * q1 + 0.2 * q2;
        break;
      case 'design':
        T = 0.1 * gaa + 0.1 * v('dgp1') + 0.1 * v('dgp2') + 0.2 * v('dgp3') + 0.2 * q2 + 0.3 * f;
        status = 'Course grade requires end-term attendance and final project score >60/100.';
        break;
      case 'financefor':
        T = 0.1 * gaa + 0.25 * q1 + 0.3 * v('dgp') + 0.35 * f;
        break;
      case 'bigdata':
        T = Math.min(100, 0.1 * gaa + 0.3 * f + 0.2 * v('dop1') + 0.4 * v('dop2') + v('dbonus'));
        bonusText = `${v('dbonus')} entered (max 5; total capped at 100)`;
        status =
          'Course grade eligibility requires end-term attendance and at least one programming exam ≥40.';
        break;
      case 'linear':
        T =
          0.1 * gaa +
          0.25 * v('dp') +
          Math.max(0.35 * f + 0.2 * qmax, 0.35 * f + 0.15 * q1 + 0.15 * q2);
        break;
      case 'rl':
        T = 0.05 * gaa + 0.25 * v('dgpa') + 0.2 * q1 + 0.2 * q2 + 0.3 * f + v('dbonus');
        bonusText = `${v('dbonus')} entered (max 5; instructor discretion)`;
        break;
      case 'corpfin':
        T = 0.1 * gaa + 0.4 * f + 0.2 * q1 + 0.3 * q2;
        break;
      case 'networks':
        T = 0.1 * gaa + 0.3 * f + 0.25 * q1 + 0.25 * q2 + 0.1 * v('dp');
        break;
      case 'csdesign':
        T = 0.1 * gaa + 0.4 * f + 0.2 * q1 + 0.25 * q2 + 0.05 * v('dp');
        break;
      case 'gametheory':
      case 'compiler':
      case 'os':
      case 'discrete':
        T = 0.1 * gaa + 0.4 * f + 0.25 * q1 + 0.25 * q2;
        break;
      case 'ads':
        T = 0.1 * gaa + 0.4 * f + 0.25 * q1 + 0.25 * q2 + v('dbonus');
        bonusText = `${v('dbonus')} entered (max 5; programming assignment)`;
        break;
      case 'seq':
        T = 0.1 * gaa + 0.4 * f + 0.25 * q1 + 0.25 * q2 + v('dbonus');
        bonusText = `${v('dbonus')} entered (max 5; programming assignment)`;
        break;
      case 'icdesign':
        T =
          0.1 * gaa +
          0.3 * v('dp') +
          Math.max(0.3 * f + 0.2 * qmax, 0.3 * f + 0.15 * q1 + 0.15 * q2);
        break;
      case 'etm':
        T = 0.1 * gaa + Math.max(0.6 * f + 0.2 * qmax, 0.5 * f + 0.2 * q1 + 0.2 * q2);
        status = 'Formula is marked tentative in the supplied document.';
        break;
      case 'comms':
        T = 0.1 * gaa + Math.max(0.6 * f + 0.2 * qmax, 0.4 * f + 0.2 * q1 + 0.3 * q2);
        break;
      case 'dsd':
      case 'org':
        T = 0.05 * gaa + Math.max(0.6 * f + 0.25 * qmax, 0.5 * f + 0.2 * q1 + 0.25 * q2);
        break;
    }
    gradeAndDisplay(T, status, bonusText);
  }

  function calculate() {
    const level = $('level').value,
      c = courses[$('course').value];
    if (level === 'diploma') {
      calculateDiploma(c);
      return;
    }
    if (level === 'degree') {
      calculateDegree(c);
      return;
    }
    if (level !== 'foundation') {
      return;
    }
    let total = null,
      base = null,
      status = '';
    const ids = c.python ? ['pq1', 'pf', 'pe1', 'pe2', 'weekly'] : ['q1', 'q2', 'f'];
    for (const id of ids) {
      if (!valid(id)) {
        alert('Please enter valid scores between 0 and 100.');
        return;
      }
    }
    if (c.bonus && !valid('bonus', 0, c.bonus)) {
      alert(`Bonus must be between 0 and ${c.bonus}.`);
      return;
    }
    if (c.python) {
      const q = read('pq1'),
        f = read('pf'),
        p1 = read('pe1'),
        p2 = read('pe2');
      if ([q, f, p1, p2].some((v) => v === null)) {
        alert('For Programming in Python, enter Quiz 1, End-term, OPPE 1 and OPPE 2 scores.');
        return;
      }
      total = 0.15 * q + 0.4 * f + 0.25 * Math.max(p1, p2) + 0.2 * Math.min(p1, p2);
      $('oppe1').textContent =
        $('a4').value === 'yes' &&
        document.querySelector('input[name="sct"]:checked').value === 'yes'
          ? 'Eligible'
          : 'Not eligible';
      $('oppe2').textContent =
        $('a8').value === 'yes' &&
        document.querySelector('input[name="sct"]:checked').value === 'yes' &&
        read('weekly') !== null &&
        read('weekly') >= 40
          ? 'Eligible'
          : 'Not eligible';
      const oppeEligible =
        $('oppe1').textContent === 'Eligible' || $('oppe2').textContent === 'Eligible';
      $('endEligible').textContent =
        read('weekly') !== null && read('weekly') >= 40 && oppeEligible
          ? 'Eligible'
          : 'Not eligible';
      status =
        'Calculated from the supplied Python course formula. Eligibility is checked separately below.';
    } else {
      const q1 = read('q1'),
        q2 = read('q2'),
        f = read('f');
      if (q1 === null || q2 === null || f === null) {
        alert('Enter Quiz 1, Quiz 2 and End-term scores.');
        return;
      }
      base = Math.max(0.6 * f + 0.3 * Math.max(q1, q2), 0.45 * f + 0.25 * q1 + 0.3 * q2);
      if (c.bonus) {
        const b = read('bonus') || 0;
        total = Math.min(100, base);
        status =
          b > 0
            ? 'Base score shown; bonus not automatically applied because the course pass condition needs verification.'
            : 'Calculated using the course formula.';
        $('bonusResult').textContent = b > 0 ? `${b} entered · not applied` : '0 marks';
      } else {
        total = base;
        status = 'Calculated using the course formula.';
        $('bonusResult').textContent = '0 marks';
      }
    }
    gradeAndDisplay(
      total,
      status,
      c.bonus ? 'Bonus handled per course conditions' : 'Not applicable'
    );
  }
  $('level').addEventListener('change', populateCourses);
  $('course').addEventListener('change', showCourse);
  $('calculate').addEventListener('click', calculate);
  $('reset').addEventListener('click', () => {
    document
      .querySelectorAll('.grade-calculator input[type=number]')
      .forEach((i) => (i.value = ''));
    $('a4').value = 'yes';
    $('a8').value = 'yes';
    document.querySelector('input[name="sct"][value="yes"]').checked = true;
    showCourse();
  });
  populateCourses();
});
</script>

<style scoped>
.grade-calculator {
  font-family: var(--font);
  background: var(--card);
  color: var(--ink);
}

.grade-calculator * {
  box-sizing: border-box;
}

.grade-calculator {
  margin: 0;
  background: var(--card);
  color: var(--ink);
  font-family: var(--font);
}

.grade-calculator button,
.grade-calculator input,
.grade-calculator select {
  font: inherit;
}

.grade-calculator .topbar {
  height: 68px;
  border-bottom: 1px solid var(--line);
  background: color-mix(in srgb, var(--card) 90%, transparent);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 max(24px, calc((100% - 1180px) / 2));
  gap: 20px;
  position: sticky;
  top: 0;
  z-index: 5;
  backdrop-filter: blur(12px);
}

.grade-calculator .brand {
  display: flex;
  align-items: center;
  gap: 11px;
  min-width: max-content;
}

.grade-calculator .brand-mark {
  width: 39px;
  height: 39px;
  border-radius: 50%;
  background: var(--ink);
  color: var(--mari-ink);
  display: grid;
  place-items: center;
  font-size: 20px;
  border: 2px solid var(--mari);
}

.grade-calculator .brand-name {
  font-size: 15px;
  font-weight: 800;
  line-height: 1.15;
}

.grade-calculator .brand-sub {
  font-size: 10px;
  color: var(--ink-2);
  margin-top: 3px;
}

.grade-calculator .nav {
  display: flex;
  align-items: center;
  gap: 24px;
  color: var(--ink-2);
  font-size: 13px;
  font-weight: 600;
}

.grade-calculator .nav span {
  padding: 8px 0;
}

.grade-calculator .nav .active {
  color: var(--ink);
  border-bottom: 2px solid var(--mari);
}

.grade-calculator .pill {
  border: 1px solid var(--ink);
  background: var(--ink);
  color: var(--on-mari);
  padding: 10px 17px;
  border-radius: 30px;
  font-size: 12px;
  font-weight: 600;
}

.grade-calculator main {
  max-width: 1180px;
  margin: 0 auto;
  padding: 44px 24px 70px;
}

.grade-calculator .hero {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 20px;
  margin-bottom: 27px;
}

.grade-calculator .eyebrow {
  color: var(--mari-ink);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 1.7px;
  text-transform: uppercase;
}

.grade-calculator h1 {
  font-size: clamp(30px, 4vw, 43px);
  letter-spacing: -1.8px;
  line-height: 1.15;
  margin: 8px 0;
}

.grade-calculator .subtitle {
  color: var(--ink-2);
  font-size: 14px;
  max-width: 660px;
  line-height: 1.7;
}

.grade-calculator .stats {
  display: flex;
  gap: 25px;
  text-align: center;
  flex-shrink: 0;
}

.grade-calculator .stat strong {
  display: block;
  font-size: 25px;
  line-height: 1.2;
}

.grade-calculator .stat small {
  font-size: 11px;
  color: var(--ink-2);
}

.grade-calculator .tabs {
  display: flex;
  gap: 5px;
  padding: 5px;
  background: var(--sunk);
  border-radius: 30px;
  width: max-content;
  max-width: 100%;
  margin-bottom: 25px;
}

.grade-calculator .tab {
  border: 0;
  background: transparent;
  padding: 10px 17px;
  border-radius: 24px;
  color: var(--ink-2);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
}

.grade-calculator .tab.active {
  background: var(--ink);
  color: var(--on-mari);
}

.grade-calculator .layout {
  display: grid;
  grid-template-columns: minmax(0, 1.55fr) minmax(270px, 0.8fr);
  gap: 22px;
  align-items: start;
}

.grade-calculator .panel {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 20px;
  padding: 25px;
  box-shadow: var(--shadow);
}

.grade-calculator .panel-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 15px;
  margin-bottom: 22px;
}

.grade-calculator .section-number {
  color: var(--mari-ink);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 1px;
}

.grade-calculator h2 {
  font-size: 21px;
  letter-spacing: -0.6px;
  margin: 5px 0 4px;
}

.grade-calculator .helper {
  font-size: 12px;
  color: var(--ink-2);
  line-height: 1.6;
}

.grade-calculator label {
  display: block;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 8px;
}

.grade-calculator select,
.grade-calculator input[type='number'] {
  width: 100%;
  background: var(--card);
  border: 1px solid var(--line-strong);
  border-radius: 10px;
  padding: 13px 14px;
  color: var(--ink);
  outline: none;
  transition: 0.2s;
}

.grade-calculator select:focus,
.grade-calculator input:focus {
  border-color: var(--mari);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--mari) 10%, transparent);
}

.grade-calculator .field {
  margin-bottom: 19px;
}

.grade-calculator .field small {
  display: block;
  color: var(--ink-2);
  font-size: 10px;
  margin-top: 6px;
}

.grade-calculator .score-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0 16px;
}

.grade-calculator .note {
  border: 1px solid var(--line);
  background: var(--mari-soft);
  border-radius: 12px;
  padding: 13px 15px;
  font-size: 11px;
  color: var(--ink-2);
  line-height: 1.65;
  margin: 6px 0 22px;
}

.grade-calculator .note strong {
  color: var(--ink);
}

.grade-calculator .exam-toggle {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.grade-calculator .choice {
  position: relative;
}

.grade-calculator .choice input {
  position: absolute;
  opacity: 0;
  pointer-events: none;
}

.grade-calculator .choice span {
  display: block;
  text-align: center;
  border: 1px solid var(--line-strong);
  border-radius: 10px;
  padding: 12px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 600;
  background: var(--card);
}

.grade-calculator .choice input:checked + span {
  background: var(--ink);
  border-color: var(--ink);
  color: var(--on-mari);
}

.grade-calculator .primary {
  width: 100%;
  border: 0;
  border-radius: 11px;
  background: var(--ink);
  color: var(--on-mari);
  padding: 15px 18px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: 0.2s;
  margin-top: 2px;
}

.grade-calculator .primary:hover {
  background: var(--mari-ink);
  transform: translateY(-1px);
}

.grade-calculator .secondary {
  border: 1px solid var(--line);
  border-radius: 10px;
  background: transparent;
  color: var(--ink-2);
  padding: 10px 13px;
  font-size: 11px;
  cursor: pointer;
}

.grade-calculator .result-panel {
  position: sticky;
  top: 90px;
}

.grade-calculator .result-top {
  background: var(--mari-soft);
  border: 1px solid var(--line);
  border-radius: 15px;
  padding: 19px;
  margin-bottom: 17px;
}

.grade-calculator .result-label {
  font-size: 11px;
  color: var(--mari-ink);
  font-weight: 600;
}

.grade-calculator .score {
  font-size: 49px;
  font-weight: 800;
  letter-spacing: -2px;
  line-height: 1.25;
  margin: 3px 0;
  color: var(--ink);
}

.grade-calculator .score span {
  font-size: 15px;
  font-weight: 500;
  letter-spacing: 0;
  color: var(--ink-2);
}

.grade-calculator .result-status {
  font-size: 11px;
  color: var(--ink-2);
  line-height: 1.6;
}

.grade-calculator .grade-row {
  display: flex;
  align-items: center;
  gap: 13px;
  margin: 0 0 17px;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: var(--card);
}

.grade-calculator .grade-letter {
  width: 54px;
  height: 54px;
  flex-shrink: 0;
  border-radius: 13px;
  display: grid;
  place-items: center;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-size: 25px;
  font-weight: 800;
}

.grade-calculator .grade-meta {
  flex: 1;
}

.grade-calculator .grade-meta strong {
  display: block;
  font-size: 13px;
}

.grade-calculator .grade-meta small {
  display: block;
  color: var(--ink-2);
  font-size: 10px;
  margin-top: 3px;
}

.grade-calculator .grade-points {
  font-size: 20px;
  font-weight: 800;
}

.grade-calculator .result-line {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  padding: 12px 0;
  border-bottom: 1px solid var(--line);
  font-size: 12px;
}

.grade-calculator .result-line:last-child {
  border-bottom: 0;
}

.grade-calculator .result-line span {
  color: var(--ink-2);
}

.grade-calculator .result-line strong {
  text-align: right;
}

.grade-calculator .formula {
  margin-top: 17px;
  background: var(--sunk);
  border-radius: 12px;
  padding: 14px;
  font-size: 11px;
  line-height: 1.8;
  color: var(--ink-2);
  overflow-wrap: anywhere;
}

.grade-calculator .formula code {
  font-family: var(--mono);
  color: var(--ink);
}

.grade-calculator .result-title {
  font-size: 15px;
  font-weight: 700;
  margin: 0 0 10px;
}

.grade-calculator .mini-title {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--mari-ink);
  font-weight: 700;
  margin: 21px 0 8px;
}

.grade-calculator .hidden {
  display: none;
}

.grade-calculator footer {
  border-top: 1px solid var(--line);
  padding: 20px 24px;
  text-align: center;
  font-size: 11px;
  color: var(--ink-3);
}

@media (max-width: 860px) {
  .grade-calculator .topbar {
    padding: 12px 18px;
    height: auto;
    flex-wrap: wrap;
  }

  .grade-calculator .nav {
    order: 3;
    width: 100%;
    justify-content: space-between;
    gap: 10px;
  }

  .grade-calculator .nav span {
    font-size: 11px;
  }

  .grade-calculator .hero {
    align-items: flex-start;
    flex-direction: column;
  }

  .grade-calculator .stats {
    gap: 22px;
  }

  .grade-calculator .layout {
    grid-template-columns: 1fr;
  }

  .grade-calculator .result-panel {
    position: static;
  }

  .grade-calculator .panel {
    padding: 20px;
  }
}

@media (max-width: 560px) {
  .grade-calculator main {
    padding: 28px 14px 45px;
  }

  .grade-calculator .score-grid {
    grid-template-columns: 1fr;
  }

  .grade-calculator .tabs {
    width: 100%;
    overflow: auto;
  }

  .grade-calculator .tab {
    white-space: nowrap;
    padding: 10px 13px;
  }

  .grade-calculator .panel {
    border-radius: 16px;
  }

  .grade-calculator .brand-sub {
    display: none;
  }

  .grade-calculator .pill {
    padding: 8px 12px;
  }
}

/* Match Diploma and Degree fields with Foundation styling */
.grade-calculator :deep(#diplomaFields .score-grid) {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0 16px;
}

.grade-calculator :deep(#diplomaFields .field) {
  min-width: 0;
  margin-bottom: 19px;
}

.grade-calculator :deep(#diplomaFields label) {
  display: block;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 8px;
  line-height: 1.5;
}

.grade-calculator :deep(#diplomaFields input[type='number']) {
  display: block;
  width: 100%;
  min-width: 0;
  box-sizing: border-box;
  background: var(--card);
  border: 1px solid var(--line-strong);
  border-radius: 10px;
  padding: 13px 14px;
  color: var(--ink);
  font: inherit;
  outline: none;
  transition: 0.2s;
}

.grade-calculator :deep(#diplomaFields input[type='number']:focus) {
  border-color: var(--mari);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--mari) 10%, transparent);
}

@media (max-width: 560px) {
  .grade-calculator :deep(#diplomaFields .score-grid) {
    grid-template-columns: 1fr;
  }
}
.grade-calculator .primary {
  color: var(--card);
  -webkit-text-fill-color: var(--card);
}
</style>

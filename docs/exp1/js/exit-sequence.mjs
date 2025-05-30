import { settings } from "../config.mjs";

const preSurveyMessage = {
  type: jsPsychHtmlButtonResponse,
  stimulus: () => {
    return `<p>You've completed the experiment!\
      </br>On the next page, you'll be shown a brief set of questions about how the experiment went.\
      </br>Once you submit your answers, your data will be recorded and I will reach out about the raffle if you win!</p>`;
  },
  choices: ["Continue"],
  margin_vertical: "20px",
};

const exitSurvey = {
  type: jsPsychSurvey,
  pages: [
    [
      {
        type: "html",
        prompt: "Please answer the following questions:",
      },
      {
        type: "multi-choice",
        name: "participantGender",
        prompt: "What is your gender?",
        options: ["Male", "Female", "Non-binary", "Other"],
        columns: 0,
        required: true,
      },
      {
        type: "text",
        name: "participantYears",
        prompt: "How many years old are you?",
        placeholder: "18",
        textbox_columns: 5,
        required: true,
      },
      {
        type: "multi-choice",
        name: "participantRace",
        prompt: "What is your race?",
        options: [
          "White",
          "Black/African American",
          "American Indian/Alaska Native",
          "Asian",
          "Native Hawaiian/Pacific Islander",
          "Multiracial/Mixed",
          "Other",
        ],
        columns: 0,
        required: true,
      },
      {
        type: "multi-choice",
        name: "participantEthnicity",
        prompt: "What is your ethnicity?",
        options: ["Hispanic", "Non-Hispanic"],
        columns: 0,
        required: true,
      },
      {
        type: "multi-choice",
        name: "inputDevice",
        prompt:
          "Which of the following devices did you use to complete this study?",
        options: ["Mouse", "Trackpad", "Touch Screen", "Stylus", "Other"],
        columns: 0,
        required: true,
      },
      {
        type: "likert",
        name: "judgedDifficulty",
        prompt: "How difficult did you find this study?",
        likert_scale_min_label: "Very Easy",
        likert_scale_max_label: "Very Hard",
        likert_scale_values: [
          { value: 1 },
          { value: 2 },
          { value: 3 },
          { value: 4 },
          { value: 5 },
        ],
        required: true,
      },
      {
        type: "likert",
        name: "participantEffort",
        prompt:
          "How much effort did you put into the game? Your response will not effect your final compensation.",
        likert_scale_min_label: "Low Effort",
        likert_scale_max_label: "High Effort",
        likert_scale_values: [
          { value: 1 },
          { value: 2 },
          { value: 3 },
          { value: 4 },
          { value: 5 },
        ],
        required: true,
      },
      {
        type: "text",
        name: "participantComments",
        prompt:
          "What factors influenced how you decided to respond? Do you have any other comments or feedback to share with us about your experience?",
        placeholder: "I had a lot of fun!",
        textbox_rows: 4,
        required: false,
      },
      {
        type: "text",
        name: "TechnicalDifficultiesFreeResp",
        prompt:
          "If you encountered any technical difficulties, please briefly describe the issue.",
        placeholder: "I did not encounter any technical difficulities.",
        textbox_rows: 4,
        required: false,
      },
    ],
  ],
  on_start: function () {
    gs.session_data.endExperimentTS = Date.now();
  },
  on_finish: function () {
    this.jsPsych.data.write(gs.session_data);
  },
};

const saveData = {
  type: jsPsychPipe,
  action: "save",
  experiment_id: settings.study_metadata.datapipe_experiment_id,
  filename: `${settings.study_metadata.project}-${settings.study_metadata.experiment}-${settings.study_metadata.iteration_name}-${settings.session_data.gameID}.csv`,
  data_string: () => jsPsych.data.get().csv(),
};

const goodbye = {
  type: jsPsychHtmlButtonResponse,
  stimulus: `<p>Thank you for participating in our study!</p>
             <p>Your responses have been recorded.</p>
             <p>You may close the tab now. If you are eligible for the raffle, we will contact you via email.</p>`,
  choices: ["Finish"],
  margin_vertical: "20px",
  on_finish: () => {
    window.onbeforeunload = null;
    document.onfullscreenchange = null;
  },
};

export const exitSurveySequence = [
  preSurveyMessage,
  exitSurvey,
  saveData,
  goodbye,
];

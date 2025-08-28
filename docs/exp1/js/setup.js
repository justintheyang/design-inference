import { loadingSequence } from "./loading-sequence.mjs";
import { instructionSequence } from "./instructions.mjs";
import { exitSurveySequence } from "./exit-sequence.mjs";
import { getJsPsych } from "./jspsych-singleton.mjs";
import { settings } from "../config.mjs";

export function setupGame() {
  const jsPsych = getJsPsych();

  const experiment_assets = [
    "assets/1_cook.png",
    "assets/2_cooks.png",
    "assets/onion_lettuce.png",
    "assets/tomato_lettuce.png",
    "assets/instructions/1_cooking_demo.gif",
    "assets/instructions/2_kitchen_components.png",
    "assets/instructions/3_recipes_schematic.png",
    "assets/instructions/4_example_trial.png",
  ];

// TODO: need if statement: if cooks, take first 18 else take last 18
  // TODO: COPY trial_01-36 to the assets/stims folder (trials 1-36 are in stimuli/s1_design_inference/either img or txt)
const trial_stims = [
  "assets/stims/trial_01.png",
  "assets/stims/trial_02.png",
  "assets/stims/trial_03.png",
  "assets/stims/trial_04.png",
  "assets/stims/trial_05.png",
  "assets/stims/trial_06.png",
  "assets/stims/trial_07.png",
  "assets/stims/trial_08.png",
  "assets/stims/trial_09.png",
  "assets/stims/trial_10.png",
  "assets/stims/trial_11.png",
  "assets/stims/trial_12.png",
  "assets/stims/trial_13.png",
  "assets/stims/trial_14.png",
  "assets/stims/trial_15.png",
  "assets/stims/trial_16.png",
  "assets/stims/trial_17.png",
  "assets/stims/trial_18.png",
  "assets/stims/trial_19.png",
  "assets/stims/trial_20.png",
  "assets/stims/trial_21.png",
  "assets/stims/trial_22.png",
  "assets/stims/trial_23.png",
  "assets/stims/trial_24.png",
  "assets/stims/trial_25.png",
  "assets/stims/trial_26.png",
  "assets/stims/trial_27.png",
  "assets/stims/trial_28.png",
  "assets/stims/trial_29.png",
  "assets/stims/trial_30.png",
  "assets/stims/trial_31.png",
  "assets/stims/trial_32.png",
  "assets/stims/trial_33.png",
  "assets/stims/trial_34.png",
  "assets/stims/trial_35.png",
  "assets/stims/trial_36.png",
];

  // trial objects

  let selected_stims;
  let question;

  if (settings.study_metadata.condition === "cooks") {
    selected_stims = trial_stims.slice(0, 18);   // first half
    question = [
        {
          prompt: "How many cooks was this kitchen made for?",
          name: "intent_agents",
          min_label: "<img src='assets/1_cook.png' style='height: 60px;'>",
          max_label: "<img src='assets/2_cooks.png' style='height: 60px;'>",
        }
      ];
  } else if (settings.study_metadata.condition === "dish") {
    selected_stims = trial_stims.slice(18, 36);  // second half
    question = [
      {
          prompt: "What dish was this kitchen made for?",
          name: "intent_recipe",
          min_label:
            "<img src='assets/tomato_lettuce.png' style='height: 60px;'>",
          max_label:
            "<img src='assets/onion_lettuce.png' style='height: 60px;'>",
        }
    ];
  }

  const inference_trials = _.map(_.shuffle(selected_stims), (stim, i) => {
    return {
      type: jsPsychSurveySlider,
      // trial stimuli image
      preamble: `<img src="${stim}" style="height: 450px;">`,
      questions: question,
      require_movement: true,
      slider_width: 800,
    };
  });

  let trials = [];
  trials.push(...loadingSequence([...experiment_assets, ...trial_stims]));
  trials.push(...instructionSequence);
  trials.push(...inference_trials);
  trials.push(...exitSurveySequence);

  jsPsych.run(trials);
}

import { settings } from "../config.mjs";
import { getJsPsych } from "./jspsych-singleton.mjs";

let jsPsych = getJsPsych();

const getFromLastTrial = (trialType, selector) => {
  const record = jsPsych
    .data
    .get()
    .filter({ trial_type: trialType })
    .last(1)        // grab the last one
    .values()[0];   // pull out the raw object
  return record[selector];
}

const instruction_pages = [
  `<p>In this study, your task is to evaluate different <strong>kitchen layouts</strong>.</p>
  <p>Your task is to judge how each kitchen was designed to be used.</p>`,

  `<p>In each kitchen, cooks prepare food by chopping ingredients, placing them on plates, and delivering completed dishes.</p>
  <p>Their goal is to prepare a meal in as few steps as possible.</p>
  <img src="assets/instructions/1_cooking_demo.gif" height="350">`,

  `<p>Every kitchen contains similar tools and ingredients:</p>
   <ul>(placeholder for graphic)
     <li>1 cutting board</li>
     <li>1 plate</li>
     <li>1 delivery station (marked with a star)</li>
     <li>1 tomato, 1 onion, and 1 lettuce</li>
   </ul>
   <img src="assets/instructions/2_kitchen_components.png" height="300">`,

   `<p>Some kitchens are easier for one cook to use efficiently. Others work better when two cooks are working together.</p>
   <p>Similarly, some kitchens are designed to make specific meals.</p>
   <p>In this task, cooks make one of two dishes:</p>
   <img src="assets/instructions/3_recipes_schematic.png" height="300">
   `,

   `<p>On each trial, you'll see a picture of a kitchen with no chefs in it.</p>
   <p>Your task is to answer two questions:</p>
   <ul> (jank -- need to fix)
     <li>How many cooks do you think each kitchen is best suited for?</li>
     <li>Which dish do you think it's designed to make?</li>
   </ul>
   <img src="assets/instructions/4_example_trial.png" height="350">`,

   `<p>On the next screen, you will be asked a few questions to make sure everything is clear.</p>
   <p>Please do your best. You\'ll need to answer correctly to move on, but can review the instructions and try again if needed.</p>`,
];

export const instructions = {
  type: jsPsychInstructions,
  pages: instruction_pages,
  show_clickable_nav: true,
  allow_backward: true,
  allow_keys: true,
};

const comprehensionFailedTrial = {
  timeline: [
    {
      type: jsPsychHtmlButtonResponse,
      stimulus: `<p>Unfortunately, you did not answer all the questions correctly.</p> \
                 <p>Please review the instructions and try again.</p>`,
      choices: ["Try Again"],
      margin_vertical: "20px"
    }
  ],
  conditional_function: function() {
    const responses = getFromLastTrial("survey-multi-choice", "response");
    if (
      responses.recipeFlexibility === "True, it is possible for either dish to be made in all kitchens." &&
      responses.agentDesign === "True, some kitchens are designed for one cook, while others are designed for two cooks." &&
      responses.recipeDesign === "True, some kitchens are designed for one dish, while others are designed for the other dish."
    ) {
      return false;
    } else {
      return true;
    }
  }
};

const instructionsLoop = {
  timeline: [
    instructions, 
    {
      type: jsPsychSurveyMultiChoice,
      preamble: "<strong>Comprehension Check</strong>",
      questions: [
        {
          prompt: "True or False: It is possible for either dish to be made in all kitchens.",
          name: "recipeFlexibility",
          options: [
            "True, it is possible for either dish to be made in all kitchens.",
            "False, in some kitchens it is impossible to make one of the dishes."
          ],
          required: true
        },
        {
          prompt: "True or False: Some kitchens are better designed for one cook, while others are designed for two cooks.",
          name: "agentDesign",
          options: [
            "True, some kitchens are designed for one cook, while others are designed for two cooks.",
            "False, all kitchens are designed to work equally well for any number of cooks."
          ],
          required: true
        },
        {
          prompt: "True or False: Some kitchens are designed for one dish, while others are designed for the other dish.",
          name: "recipeDesign",
          options: [
            "True, some kitchens are designed for one dish, while others are designed for the other dish.",
            "False, all kitchens are equally designed for both dishes."
          ],
          required: true
        }
      ]
    },
    comprehensionFailedTrial
  ],
  loop_function: (data) => {
    const responses = data['trials'][1]['response'];
    if (
      responses.recipeFlexibility === "True, it is possible for either dish to be made in all kitchens." &&
      responses.agentDesign === "True, some kitchens are designed for one cook, while others are designed for two cooks." &&
      responses.recipeDesign === "True, some kitchens are designed for one dish, while others are designed for the other dish."
    ) {
      return false;
    } else {
      settings.session_data.comprehensionAttempts += 1;
      return true;
    }
  }
};

const instructionsConclusion = {
  type: jsPsychHtmlButtonResponse,
  stimulus: `
    <p>Congrats! You've learned everything you need to know.</p> \
    <p>In total, you will be making judgments for nine kitchens.</p> \
    <p>Please click the continue button to get started. Thank you for participating!</p>`,
  choices: ["Continue"],
  margin_vertical: "20px"
}

export const instructionSequence = [instructionsLoop, instructionsConclusion];
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

// Get instruction pages with inline conditional logic
const getInstructionPages = () => {
  const condition = settings.study_metadata.condition;
  
  return [
    // Page 1
    `<p>In this study, you will be evaluating different <strong>kitchen layouts</strong>.</p>
    <p>Your task is to judge how each kitchen was designed to be used.</p>`,

    // Page 2: Overview and demo
    `<p>In each kitchen, cooks try to prepare a salad while taking as few steps as possible.</p>
    <p>In the figure below, a cook is making a salad using a tomato and a lettuce.</p>
    <img src="assets/instructions/${condition === "cooks" ? "tomato_salad_demo.gif" : "lettuce_salad_demo.gif"}" height="300">`,

    // Page 3: Recipe
    `<p>Cooks complete an order by first chopping the necessary ingredients, then combining them on a plate, and finally delivering it to the serving station.</p>
    ${condition === "dish" ? `
    <p>There are two possible salads that the cooks make: either a <strong>tomato</strong> salad, or an <strong>onion</strong> salad.</p>
    <img src="assets/instructions/two_recipes.png" height="300">` : `<img src="assets/instructions/one_recipe.png" height="300">`}`,

    // Page 4: Stations
    `<p>Salad ingredients are stored in <strong>food dispensers</strong>. To grab a tomato, for example, a cook walks up to the tomato dispenser and interacts with it to grab one.</p>
    <img src="assets/instructions/food_dispenser_demo.gif" height="300">`,

    // Page 5: Chopping
    `<p>Cooks chop ingredients at the <strong>chopping board</strong>. To use it, they must first move in front of the board and interact with it while holding an ingredient.</p>
    <p>Chopping boards cannot be moved around.</p>
    <img src="assets/instructions/chopping_demo.gif" height="300">`,

    // Page 6: Combining and plating
    `<p>After the ingredients are chopped, they can be put on a plate and combined into a salad.</p>
    <p>Ingredients may be combined and plated in any order. For example, in the left graphic, the cook first combines the ingredients together before putting it on the plate. On the right, the cook first plates the chopped lettuce before adding in the tomato.</p>
    <img src="assets/instructions/plating_order1.gif" height="300">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <img src="assets/instructions/plating_order2.gif" height="300">`,

    // Page 7: Delivery
    `<p>After the dish has been plated, it is now ready for delivery! To finish the order, the cook must bring it to the delivery station so it can be sent out to the customer.</p>
    <img src="assets/instructions/${condition === "cooks" ? "delivery_onion.gif" : "delivery_tomato.gif"}" height="300">`,

    // Page 8a: Condition-specific content
    `${condition === "cooks" ? `
    <p>Cooks can either work alone or collaborate with another cook to make the salad. Some kitchens are designed for one cook to work alone. Others are designed for two cooks.</p>
    <p>Cooks can use counter spaces to pass ingredients and plates to each other over. This includes normal counters, cutting boards, and also food dispensers!</p>
    <img src="assets/instructions/cooks_passing.gif" height="300">` : `
    <p>Some kitchens are designed to make an onion salad. Others are designed to make a tomato salad.</p>
    <img src="assets/instructions/dishes_comparison.png" height="300">`}`,

    // Page 8b: Cooks collision (only for cooks condition)
    ...(condition === "cooks" ? [`
    <p>But watch your surroundings — two cooks cannot occupy the same space and can block each other from getting where they want!</p>
    <img src="assets/instructions/cooks_collision.gif" height="300">`] : []),

    // Page 9: Examples
    `<p>To get a better understanding of how this works, take a look at how ${condition === "cooks" ? "one or two cooks make a salad." : "these cooks make an onion and a tomato salad"}</p>
    <img src="assets/instructions/${condition === "cooks" ? "cooks_collaboration1.gif" : "onion_salad_demo2.gif"}" height="300">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <img src="assets/instructions/${condition === "cooks" ? "cooks_collaboration2.gif" : "onion_tomato_demo.gif"}" height="300">`,

    // Page 10: Task description
    `<p>Your task is to look at a set of kitchen layouts and answer ${condition === "cooks" ? "how many cooks it was designed for." : "which dish it was designed for."}</p>${condition === "cooks" ? `
    <p>If there is one cook, they will always start on the blue square. If there are two cooks, the second cook will start on the green square.</p>` : `<p>The blue square shows the starting location of the cook.</p>`}
    <img src="assets/instructions/${condition === "cooks" ? "demo_trial_cook.png" : "demo_trial_dish.png"}" height="400">`,

    // Page 11: Comprehension check
    `<p>On the next screen, you will be asked a few questions to make sure everything is clear.</p>
    <p>Please do your best. You\'ll need to answer correctly to move on, but can review the instructions and try again if needed.</p>`
  ];
};

// Export instructions as a function that gets called after condition is set
export const getInstructions = () => {
  return {
    type: jsPsychInstructions,
    pages: getInstructionPages(),
    show_clickable_nav: true,
    allow_backward: true,
    allow_keys: true,
  };
};

const getComprehensionQuestions = () => {
  const condition = settings.study_metadata.condition;
  
  const baseQuestions = [
    {
      prompt: "True or False: Cooks try to take as few steps as possible to complete an order.",
      name: "fewSteps",
      options: [
        "True, cooks try to take as few steps as possible to complete an order.",
        "False, cooks do not try to minimize the number of steps they take to complete an order."
      ],
      required: true
    },
    {
      prompt: "True or False: Ingredients may be combined and plated in any order.",
      name: "platingOrder",
      options: [
        "True, there is no particular order for combining and plating a dish.",
        "False, the vegetables must be combined prior to being plated."
      ],
      required: true
    },
    {
      prompt: "True or False: It is possible for ingredients to be placed on empty countertops.",
      name: "counterPlacement",
      options: [
        "True, it is possible for ingredients to be placed on empty counters.",
        "False, ingredients can only be placed on counters with other tools or ingredients on them."
      ],
      required: true
    }
  ];
  
  if (condition === "cooks") {
    return [
      ...baseQuestions,
      {
        prompt: "True or False: Some kitchens are designed for one cook, while others are designed for two cooks.",
        name: "agentDesign",
        options: [
          "True, some kitchens are designed for one cook, while others are designed for two cooks.",
          "False, all kitchens are designed to work equally well for any number of cooks."
        ],
        required: true
      },
      {
        prompt: "True or False: Cooks can only pass ingredients and plates to each other by placing them down on counters, cutting boards, and food dispensers.",
        name: "cooksPassing",
        options: [
          "True, cooks can only pass ingredients and plates to each other by placing them down on counters, cutting boards, and food dispensers.",
          "False, cooks can directly hand ingredients and plates to each other without placing them down first."
        ],
        required: true
      }
    ];
  } else if (condition === "dish") {
    return [
      ...baseQuestions,
      {
        prompt: "True or False: Some kitchens are designed for one dish, while others are designed for the other dish.",
        name: "recipeDesign",
        options: [
          "True, some kitchens are designed for one dish, while others are designed for the other dish.",
          "False, all kitchens are equally designed for both dishes."
        ],
        required: true
      }
    ];
  }
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
    const condition = settings.study_metadata.condition;
    if (
      responses.fewSteps === "True, cooks try to take as few steps as possible to complete an order." &&
      responses.platingOrder === "True, there is no particular order for combining and plating a dish." &&
      responses.counterPlacement === "True, it is possible for ingredients to be placed on empty counters." &&
      (condition === "cooks" ? 
        responses.agentDesign === "True, some kitchens are designed for one cook, while others are designed for two cooks." &&
        responses.cooksPassing === "True, cooks can only pass ingredients and plates to each other by placing them down on counters, cutting boards, and food dispensers." : 
        responses.recipeDesign === "True, some kitchens are designed for one dish, while others are designed for the other dish."
      )
    ) {
      return false;
    } else {
      return true;
    }
  }
};

const instructionsLoop = {
  timeline: [
    getInstructions(), 
    {
      type: jsPsychSurveyMultiChoice,
      preamble: "<strong>Comprehension Check</strong>",
      questions: getComprehensionQuestions()
    },
    comprehensionFailedTrial
  ],
  loop_function: (data) => {
    const responses = data['trials'][1]['response'];
    const condition = settings.study_metadata.condition;
    
    // Base questions that are always checked
    const baseCorrect = (
      responses.fewSteps === "True, cooks try to take as few steps as possible to complete an order." &&
      responses.platingOrder === "True, there is no particular order for combining and plating a dish." &&
      responses.counterPlacement === "True, it is possible for ingredients to be placed on empty counters."
    );
    
    if (condition === "cooks") {
      const cooksCorrect = (
        responses.agentDesign === "True, some kitchens are designed for one cook, while others are designed for two cooks." &&
        responses.cooksPassing === "True, cooks can only pass ingredients and plates to each other by placing them down on counters, cutting boards, and food dispensers."
      );
      if (baseCorrect && cooksCorrect) {
        return false;
      } else {
        settings.session_data.comprehensionAttempts += 1;
        return true;
      }
    } else if (condition === "dish") {
      const dishCorrect = (
        responses.recipeDesign === "True, some kitchens are designed for one dish, while others are designed for the other dish."
      );
      if (baseCorrect && dishCorrect) {
        return false;
      } else {
        settings.session_data.comprehensionAttempts += 1;
        return true;
      }
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
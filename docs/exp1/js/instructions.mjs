const instruction_pages = [""];

// 1) In this study, your task is to X. something kitchen is designed for. You will be {making judgments on a bunch of different kitchens}
// 2) There are kitchens where one or two cooks try to make one of two possible dishes. (gif of cooks doing their thing)
// 3) about kitchens: The kitchen may contain cutting boards, which can be used to chop foods. Foods can also be put on plates, and all of these can be picked up or put down by the chefs at any time. The kitchen also contains a delivery station marked by a star. (graphic: the different types of items in the kitchen)
// 4) agents alone or coordinate (gif: one agent and two agents display side by side)
// 5) onion lettuce or tomato lettuce (graphic schematic of the recipe)
// 6) some kitchens are made for one cook, some kitchens are made for two cooks. Some are more specialized to make one over another, but all kitchens come fully equipped to make either recipe. Your task is to look at a kitchen and answer to what extent you think it was made for one or two cooks, and what dish it was made for. (graphic: kitchen with a question mark, with the two options of agents and recipe below it)
// 7)   `<p>Great job!</p> \
//    <p>On the next screen, you\'ll be asked a few questions confirming that everything is crystal clear.</p>\
//    <p>Please do your best. You will be asked to review the instructions and try again until you answer all questions correctly.</p>`
// 8) instructions conclusion (# trials, raffle information, etc.)

export const instructions = {
  type: jsPsychInstructions,
  pages: instruction_pages,
  show_clickable_nav: true,
};

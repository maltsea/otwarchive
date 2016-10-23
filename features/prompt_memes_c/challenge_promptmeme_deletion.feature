@collections @challenges @promptmemes
Feature: Prompt Meme Challenge
  In order to have an archive full of works
  As a humble user
  I want to create a prompt meme and post to it

  Scenario: As a co-moderator I can't delete whole signups

  Given I have Battle 12 prompt meme fully set up
  # TODO: fix the form in the partial collection_participants/participant_form
  # TODO: we allow maintainers to delete whole sign-ups
  Given I have added a co-moderator "mod2" to collection "Battle 12"
  When I am logged in as "myname1"
  When I sign up for Battle 12 with combination A
  When I am logged in as "mod2"
  When I start to delete the signup by "myname1"
  Then I should see "myname1"
    And I should not see a link "myname1"

  Scenario: As a co-moderator I can delete prompts

  Given I have Battle 12 prompt meme fully set up
  # TODO: fix the form in the partial collection_participants/participant_form and make sure the moderator is a real mod. Can't delete prompts because there are only 2 and so are not allowed to be deleted (needs to be three)
  Given I have added a co-moderator "mod2" to collection "Battle 12"
  When I am logged in as "myname1"
  When I sign up for Battle 12 with combination C
  When I add a new prompt to my signup for a prompt meme
  When I am logged in as "mod2"
  When I delete the prompt by "myname1"
  Then I should see "Prompt was deleted."

  Scenario: When user deletes signup, its prompts disappear from the collection

  Given I have Battle 12 prompt meme fully set up
  When I am logged in as "myname1"
  When I sign up for Battle 12 with combination A
  When I delete my signup for the prompt meme "Battle 12"
  When I view prompts for "Battle 12"
  Then I should not see "myname1" within "ul.index"

  Scenario: When user deletes signup, the signup disappears from their dashboard

  Given I have Battle 12 prompt meme fully set up
  When I am logged in as "myname1"
  When I sign up for Battle 12 with combination A
  When I delete my signup for the prompt meme "Battle 12"
  When I go to my signups page
  Then I should see "Sign-ups (0)"
    And I should not see "Battle 12"

  Scenario: When user deletes signup, the work stays part of the collection,
  but no longer has the "In response to a prompt by" note

  Given I have Battle 12 prompt meme fully set up
    And "myname1" has signed up for Battle 12 with combination A
    And "myname2" has fulfilled a claim from Battle 12
    And "myname1" has deleted their sign up for the prompt meme "Battle 12"
  When I am logged in as "myname2"
    And I go to "Battle 12" collection's page
  Then I should see "Fulfilled Story"
  When I follow "Fulfilled Story"
  Then I should not see "In response to a prompt"
    And I should see "Battle 12"

  Scenario: When user deletes signup, the work creator can edit the work 
  normally

  Given I have Battle 12 prompt meme fully set up
    And "myname1" has signed up for Battle 12 with combination A
    And "myname2" has fulfilled a claim from Battle 12
    And "myname1" has deleted their sign up for the prompt meme "Battle 12"
  When I am logged in as "myname2"
    And I edit the work "Fulfilled Story"
    And I fill in "Additional Tags" with "My New Tag"
    And I press "Post Without Preview"
  Then I should see "Work was successfully updated."
    And I should see "My New Tag"

  Scenario: A mod can delete a prompt meme and all the claims and sign-ups will 
  be deleted with it, but the collection will remain

  Given I have Battle 12 prompt meme fully set up
    And everyone has signed up for Battle 12
    And "myname4" has claimed a prompt from Battle 12
  When I am logged in as "mod1"
    And I delete the challenge "Battle 12"
  Then I should see "Challenge settings were deleted."
    And I should not see the prompt meme dashboard for "Battle 12"
    And no one should have a claim in "Battle 12"
    And no one should be signed up for "Battle 12"
  When I go to the collections page
  Then I should see "Battle 12"

  Scenario: A user can still access their Sign-ups page after a prompt meme they 
  were signed up for has been deleted

  Given I have Battle 12 prompt meme fully set up
    And everyone has signed up for Battle 12
    And the challenge "Battle 12" is deleted
  When I am logged in as "myname1"
    And I go to my signups page
  Then I should see "Challenge Sign-ups for myname1"
    And I should not see "Battle 12"

  Scenario: A user can still access their Claims page after a prompt meme they 
  had an unfulfilled claim in has been deleted

  Given I have Battle 12 prompt meme fully set up
    And everyone has signed up for Battle 12
    And "myname1" has claimed a prompt from Battle 12
    And the challenge "Battle 12" is deleted
  When I am logged in as "myname1"
    And I go to my signups page
  Then I should see "Challenge Sign-ups for myname1"
    And I should not see "Battle 12"

  Scenario: A user can still access their Claims page after a prompt meme they 
  had a fulfilled claim in has been deleted

  Given I have Battle 12 prompt meme fully set up
    And everyone has signed up for Battle 12
    And "myname4" has fulfilled a claim from Battle 12
    And the challenge "Battle 12" is deleted
  When I am logged in as "myname4"
    And I go to my claims page
  Then I should see "My Claims"
  When I follow "Fulfilled Claims"
  Then I should not see "Battle 12"

  Scenario: The prompt line should not show on claim fills after the prompt meme 
  has been deleted

  Given I have Battle 12 prompt meme fully set up
    And everyone has signed up for Battle 12
    And "myname1" has fulfilled a claim from Battle 12
    And the challenge "Battle 12" is deleted
  When I view the work "Fulfilled Story"
  Then I should not see "In response to a prompt"

  Scenario: A mod can delete a prompt meme collection and all the claims and
  sign-ups will be deleted with it

  Given I have Battle 12 prompt meme fully set up
    And everyone has signed up for Battle 12
    And "myname1" has fulfilled a claim from Battle 12
    And the challenge "Battle 12" is deleted
  When I am logged in as "mod1"
    And I go to "Battle 12" collection's page
    And I follow "Collection Settings"
    And I follow "Delete"
  Then I should see "Are you sure you want to delete the collection Battle 12?"
  When I press "Yes, Delete Collection"
  Then I should see "Collection was successfully deleted."
    And no one should have a claim in "Battle 12"
    And no one should be signed up for "Battle 12"
  When I go to the collections page
  Then I should not see "Battle 12"

  Scenario: Claim fills should still be accessible even after the prompt meme 
  collection has been deleted

  Given I have Battle 12 prompt meme fully set up
    And everyone has signed up for Battle 12
    And "myname1" has fulfilled a claim from Battle 12
    And the collection "Battle 12" is deleted
  When I view the work "Fulfilled Story"
  Then I should see "Fulfilled Story"
    # TODO: Make an issue
    # And I should not see "In response to a prompt"
    # And I should not see "Battle 12"

  Scenario: Delete a signup, claims should also be deleted from the prompt meme's Claims list

  Given I have Battle 12 prompt meme fully set up
  When I am logged in as "myname1"
  When I sign up for Battle 12 with combination B
    And I am logged in as "myname4"
    And I claim a prompt from "Battle 12"
  When I am logged in as "myname1"
    And I delete my signup for the prompt meme "Battle 12"
  Then I should see "Challenge sign-up was deleted."
  When I am logged in as "myname4"
    And I go to my claims page
  Then I should see "Claims (0)"

  Scenario: Delete a prompt, claims should also be deleted from the user's Claims page

  Given I have Battle 12 prompt meme fully set up
  When I am logged in as "myname1"
  When I sign up for Battle 12 with combination B
    And I am logged in as "myname4"
    And I claim a prompt from "Battle 12"
  When I am logged in as "myname1"
    And I delete my signup for the prompt meme "Battle 12"
  When I am logged in as "myname4"
    And I go to my claims page
  Then I should see "Claims (0)"

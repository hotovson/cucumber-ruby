@spawn
Feature: Around hooks

  In order to support transactional scenarios for database libraries
  that provide only a block syntax for transactions, Cucumber should
  permit definition of Around hooks.

  Scenario: A single Around hook
    Given a file named "features/step_definitions/steps.rb" with:
      """
      Then /^the hook is called$/ do
        expect($hook_called).to be true
      end
      """
    And a file named "features/support/hooks.rb" with:
      """
      Around do |scenario, block|
        $hook_called = true
        block.call
      end
      """
    And a file named "features/f.feature" with:
      """
      Feature: Around hooks
        Scenario: using hook
          Then the hook is called
      """
    When I run `cucumber features/f.feature`
    Then it should pass with:
      """
      Feature: Around hooks

        Scenario: using hook      # features/f.feature:2
          Then the hook is called # features/step_definitions/steps.rb:1

      1 scenario (1 passed)
      1 step (1 passed)

      """

  Scenario: Multiple Around hooks
    Given a file named "features/step_definitions/steps.rb" with:
      """
      Then /^the hooks are called in the correct order$/ do
        expect($hooks_called).to eq ['A', 'B', 'C']
      end
      """
    And a file named "features/support/hooks.rb" with:
      """
      Around do |scenario, block|
        $hooks_called ||= []
        $hooks_called << 'A'
        block.call
      end

      Around do |scenario, block|
        $hooks_called ||= []
        $hooks_called << 'B'
        block.call
      end

      Around do |scenario, block|
        $hooks_called ||= []
        $hooks_called << 'C'
        block.call
      end
      """
    And a file named "features/f.feature" with:
      """
      Feature: Around hooks
        Scenario: using multiple hooks
          Then the hooks are called in the correct order
      """
    When I run `cucumber features/f.feature`
    Then it should pass with:
      """
      Feature: Around hooks

        Scenario: using multiple hooks                   # features/f.feature:2
          Then the hooks are called in the correct order # features/step_definitions/steps.rb:1

      1 scenario (1 passed)
      1 step (1 passed)

      """

  Scenario: Mixing Around, Before, and After hooks
    Given a file named "features/step_definitions/steps.rb" with:
      """
      Then /^the Around hook is called around Before and After hooks$/ do
        expect($hooks_called).to eq ['Around', 'Before']
      end
      """
    And a file named "features/support/hooks.rb" with:
      """
      Around do |scenario, block|
        $hooks_called ||= []
        $hooks_called << 'Around'
        block.call
        $hooks_called << 'Around'
        $hooks_called.should == ['Around', 'Before', 'After', 'Around'] #TODO: Find out why this fails using the new rspec expect syntax.
      end

      Before do |scenario|
        $hooks_called ||= []
        $hooks_called << 'Before'
      end

      After do |scenario|
        $hooks_called ||= []
        $hooks_called << 'After'
        expect($hooks_called).to eq ['Around', 'Before', 'After']
      end
      """
    And a file named "features/f.feature" with:
      """
      Feature: Around hooks
        Scenario: Mixing Around, Before, and After hooks
          Then the Around hook is called around Before and After hooks
      """
    When I run `cucumber features/f.feature`
    Then it should pass with:
      """
      Feature: Around hooks

        Scenario: Mixing Around, Before, and After hooks               # features/f.feature:2
          Then the Around hook is called around Before and After hooks # features/step_definitions/steps.rb:1

      1 scenario (1 passed)
      1 step (1 passed)

      """

  Scenario: Around hooks with tags
    Given a file named "features/step_definitions/steps.rb" with:
      """
      Then /^the Around hooks with matching tags are called$/ do
        expect($hooks_called).to eq ['one', 'one or two']
      end
      """
    And a file named "features/support/hooks.rb" with:
      """
      Around('@one') do |scenario, block|
        $hooks_called ||= []
        $hooks_called << 'one'
        block.call
      end

      Around('@one,@two') do |scenario, block|
        $hooks_called ||= []
        $hooks_called << 'one or two'
        block.call
      end

      Around('@one', '@two') do |scenario, block|
        $hooks_called ||= []
        $hooks_called << 'one and two'
        block.call
      end

      Around('@two') do |scenario, block|
        $hooks_called ||= []
        $hooks_called << 'two'
        block.call
      end
      """
    And a file named "features/f.feature" with:
      """
      Feature: Around hooks
        @one
        Scenario: Around hooks with tags
          Then the Around hooks with matching tags are called
      """
    When I run `cucumber -q -t @one features/f.feature`
    Then it should pass with:
      """
      Feature: Around hooks

        @one
        Scenario: Around hooks with tags
          Then the Around hooks with matching tags are called

      1 scenario (1 passed)
      1 step (1 passed)

      """

  Scenario: Around hooks with scenario outlines
    Given a file named "features/step_definitions/steps.rb" with:
      """
      Then /^the hook is called$/ do
        expect($hook_called).to be true
      end
      """
    And a file named "features/support/hooks.rb" with:
      """
      Around do |scenario, block|
        $hook_called = true
        block.call
      end
      """
    And a file named "features/f.feature" with:
      """
      Feature: Around hooks with scenario outlines
        Scenario Outline: using hook
          Then the hook is called

          Examples:
            | Number |
            | one    |
            | two    |
      """
    When I run `cucumber features/f.feature`
    Then it should pass with:
      """
      Feature: Around hooks with scenario outlines

        Scenario Outline: using hook # features/f.feature:2
          Then the hook is called    # features/f.feature:3

          Examples: 
            | Number |
            | one    |
            | two    |

      2 scenarios (2 passed)
      2 steps (2 passed)

      """

  Scenario: Around Hooks and the Custom World
    Given a file named "features/step_definitions/steps.rb" with:
      """
      Then /^the world should be available in the hook$/ do
        $previous_world = self
        expect($hook_world).to eq(self)
      end

      Then /^what$/ do
        expect($hook_world).not_to eq($previous_world)
      end
      """
    And a file named "features/support/hooks.rb" with:
      """
      Around do |scenario, block|
        $hook_world = self
        block.call
      end
      """
    And a file named "features/f.feature" with:
      """
      Feature: Around hooks
        Scenario: using hook
          Then the world should be available in the hook

        Scenario: using the same hook
          Then what
      """
    When I run `cucumber features/f.feature`
    Then it should pass

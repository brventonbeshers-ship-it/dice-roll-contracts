import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";

describe("dice-roll-v2", () => {
  it("should return initial total rolls as zero", () => {
    const result = simnet.callReadOnlyFn(
      "dice-roll-v2",
      "get-total-rolls",
      [],
      simnet.deployer
    );
    expect(result.result).toBeOk(Cl.uint(0));
  });

  it("should return initial total wins as zero", () => {
    const result = simnet.callReadOnlyFn(
      "dice-roll-v2",
      "get-total-wins",
      [],
      simnet.deployer
    );
    expect(result.result).toBeOk(Cl.uint(0));
  });

  it("should return default user stats", () => {
    const result = simnet.callReadOnlyFn(
      "dice-roll-v2",
      "get-user-stats",
      [Cl.standardPrincipal(simnet.deployer)],
      simnet.deployer
    );
    expect(result.result).toBeOk(
      Cl.tuple({
        rolls: Cl.uint(0),
        wins: Cl.uint(0),
        "last-roll": Cl.uint(0),
        "last-result": Cl.uint(0),
      })
    );
  });

  it("should confirm game is active", () => {
    const result = simnet.callReadOnlyFn(
      "dice-roll-v2",
      "is-game-active",
      [],
      simnet.deployer
    );
    expect(result.result).toBeOk(Cl.bool(true));
  });

  it("should reject invalid guess below 1", () => {
    const result = simnet.callPublicFn(
      "dice-roll-v2",
      "roll-dice",
      [Cl.uint(0)],
      simnet.deployer
    );
    expect(result.result).toBeErr(Cl.uint(100));
  });

  it("should reject invalid guess above 6", () => {
    const result = simnet.callPublicFn(
      "dice-roll-v2",
      "roll-dice",
      [Cl.uint(7)],
      simnet.deployer
    );
    expect(result.result).toBeErr(Cl.uint(100));
  });

  it("should allow valid roll and update stats", () => {
    const result = simnet.callPublicFn(
      "dice-roll-v2",
      "roll-dice",
      [Cl.uint(3)],
      simnet.deployer
    );
    expect(result.result.type).toBe(7); // ok response

    const stats = simnet.callReadOnlyFn(
      "dice-roll-v2",
      "get-user-stats",
      [Cl.standardPrincipal(simnet.deployer)],
      simnet.deployer
    );
    const statsValue = stats.result.value.data;
    expect(statsValue.rolls).toStrictEqual(Cl.uint(1));
  });
});

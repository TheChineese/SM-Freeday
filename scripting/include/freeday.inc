/** Double-include prevention */
#if defined _freeday_included_
  #endinput
#endif
#define _freeday_included_

public SharedPlugin:__pl_freeday =
{
	name = "freeday",
	file = "Freeday.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_war_SetNTVOptional()
{
	MarkNativeAsOptional("FREEDAY_HasFreeday");
	MarkNativeAsOptional("FREEDAY_SetFreeday");
}
#endif
 
/**
 * Checks if the Player has Freeday.
 *
 * @param client    A client index.
 * @return        True / False.
 */
native FREEDAY_HasFreeday(client);

/**
 * Checks if the Player has Freeday.
 *
 * @param client    A client index.
 * @param direct   True = Freeday will be set directly / False = Freeday will be set next round.
 * @return        True / False.
 */
native FREEDAY_SetFreeday(client, bool:direct = true);
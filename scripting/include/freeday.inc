/** Double-include prevention */
#if defined _freeday_included_
  #endinput
#endif
#define _freeday_included_
 
/**
 * Checks if the Player has Freeday.
 *
 * @param client    A client index.
 * @return        True / False.
 */
native HasFreeday(client);

/**
 * Checks if the Player has Freeday.
 *
 * @param client    A client index.
 * @param direct   True = Freeday will be set directly / False = Freeday will be set next round.
 * @return        True / False.
 */
native SetFreeday(client, bool:direct = true);
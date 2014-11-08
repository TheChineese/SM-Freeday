/** Double-include prevention */
#if defined _freeday_included_
  #endinput
#endif
#define _freeday_included_
 
/**
 * Checks if the Player has Freeday.
 *
 * @param num1    A client index.
 * @return        True / False.
 */
native HasFreeday(client);
/** Double-include prevention */
#if defined _mynatives_included_
  #endinput
#endif
#define _mynatives_included_
 
/**
 * Checks if the Player has Freeday.
 *
 * @param num1    A client index.
 * @return        True / False.
 */
native HasFreeday(client);
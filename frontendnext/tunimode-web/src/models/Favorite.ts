import { Listing } from "./Listing";
import { User } from "./User";

export interface FavoriteCollections {
  listings: Listing[];
  sellers: User[];
}

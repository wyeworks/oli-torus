import React from 'react';

export type EditorDesc = {
  slug: string;
  deliveryElement: string | React.FunctionComponent;
  authoringElement: string | React.FunctionComponent;
  icon: string;
  description: string;
  friendlyName: string;
  petiteLabel: string;
  globallyAvailable: boolean;
  enabledForProject: boolean;
  id: number;
};

export interface ActivityEditorMap {
  // Index signature
  [prop: string]: EditorDesc;
}
